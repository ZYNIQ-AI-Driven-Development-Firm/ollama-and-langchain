#!/bin/bash

# Google Cloud Deployment Script
# This script builds and deploys the ollama-and-langchain stack to Google Cloud

set -e

# Configuration
PROJECT_ID=${1:-"your-gcp-project-id"}
REGION=${2:-"us-central1"}
ZONE=${3:-"us-central1-a"}

echo "🚀 Deploying to Google Cloud Platform"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Zone: $ZONE"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "📋 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable sql.googleapis.com
gcloud services enable redis.googleapis.com

# Build images using Cloud Build
echo "🔨 Building Docker images..."
gcloud builds submit --config cloudbuild.yaml .

# Create Cloud SQL instance for PostgreSQL
echo "🗄️ Creating Cloud SQL instance..."
gcloud sql instances create ollama-postgres \
    --database-version=POSTGRES_16 \
    --tier=db-g1-small \
    --region=$REGION \
    --root-password=secure-postgres-password \
    --storage-type=SSD \
    --storage-size=20GB \
    --backup-start-time=03:00 \
    --enable-bin-log \
    --deletion-protection || echo "SQL instance might already exist"

# Create database
echo "📊 Creating database..."
gcloud sql databases create llm --instance=ollama-postgres || echo "Database might already exist"

# Create Memorystore Redis instance
echo "🔴 Creating Redis instance..."
gcloud redis instances create ollama-redis \
    --size=1 \
    --region=$REGION \
    --redis-version=redis_7_0 || echo "Redis instance might already exist"

# Create VM instance with GPU support for Ollama
echo "🖥️ Creating VM instance with GPU..."
gcloud compute instances create ollama-vm \
    --zone=$ZONE \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --image-family=cos-stable \
    --image-project=cos-cloud \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-ssd \
    --maintenance-policy=TERMINATE \
    --restart-on-failure \
    --metadata=startup-script='#!/bin/bash
# Install NVIDIA drivers
/opt/google/cos-extensions/gpu/bin/install_gpu_driver

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker

# Create app directory
mkdir -p /opt/ollama-app
cd /opt/ollama-app

# Download docker-compose file
curl -O https://raw.githubusercontent.com/your-repo/ollama-and-langchain/main/docker-compose.gcp.yml

# Set environment variables
export GCP_PROJECT_ID='$PROJECT_ID'
export POSTGRES_DSN="postgresql+psycopg://postgres:secure-postgres-password@$(gcloud sql instances describe ollama-postgres --format=\"value(ipAddresses[0].ipAddress)\"):5432/llm"
export REDIS_URL="redis://$(gcloud redis instances describe ollama-redis --region='$REGION' --format=\"value(host)\"):6379/0"
export OLLAMA_MODELS="llama3.1:8b-instruct,qwen2.5:32b-instruct"
export JWT_SECRET="$(openssl rand -base64 32)"
export ADMIN_EMAIL="admin@yourcompany.com"
export DOMAIN="your-domain.com"
export GRAFANA_ADMIN_PASSWORD="$(openssl rand -base64 16)"

# Start services
docker-compose -f docker-compose.gcp.yml up -d
' \
    --tags=ollama,http-server,https-server || echo "VM might already exist"

# Create firewall rules
echo "🔥 Creating firewall rules..."
gcloud compute firewall-rules create allow-ollama-http \
    --allow tcp:80,tcp:443,tcp:3000 \
    --source-ranges 0.0.0.0/0 \
    --target-tags ollama,http-server,https-server || echo "Firewall rule might already exist"

# Get VM external IP
VM_IP=$(gcloud compute instances describe ollama-vm --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo "✅ Deployment complete!"
echo "🌐 Access your application at: http://$VM_IP"
echo "📊 Grafana dashboard: http://$VM_IP:3000 (admin/[generated-password])"
echo ""
echo "📝 Next steps:"
echo "1. Update DNS records to point your domain to $VM_IP"
echo "2. Update the DOMAIN environment variable in the VM"
echo "3. Restart the services to enable HTTPS"
echo ""
echo "🔧 To SSH into the VM:"
echo "gcloud compute ssh ollama-vm --zone=$ZONE"
echo ""
echo "📋 To view logs:"
echo "gcloud compute ssh ollama-vm --zone=$ZONE --command='cd /opt/ollama-app && docker-compose logs -f'"