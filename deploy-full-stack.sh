#!/bin/bash
set -e

echo "🚀 Complete Ollama & LangChain Stack Deployment on VM"
echo "===================================================="

# Set default values
MACHINE_TYPE=${1:-"n2-highmem-8"}
ZONE=${2:-"us-central1-a"}
PROJECT_ID=${3:-"zyniq-core"}

echo "🎯 Configuration:"
echo "Machine Type: $MACHINE_TYPE"
echo "Zone: $ZONE"
echo "Project: $PROJECT_ID"
echo ""

# Create VM with complete stack
echo "🏗️ Creating VM with complete stack..."
gcloud compute instances create ollama-full-stack \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=300GB \
  --boot-disk-type=pd-ssd \
  --tags=http-server,https-server,ollama-server \
  --metadata=startup-script='#!/bin/bash
    set -e
    echo "🔧 Setting up complete Ollama & LangChain stack..."

    # Update system
    apt-get update && apt-get upgrade -y

    # Install required packages
    apt-get install -y \
      docker.io \
      docker-compose-plugin \
      curl \
      wget \
      git \
      htop \
      build-essential \
      python3-pip \
      nodejs \
      npm

    # Start Docker
    systemctl start docker
    systemctl enable docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    systemctl start ollama
    systemctl enable ollama

    # Clone the repository
    cd /opt
    git clone https://github.com/ZYNIQ-AI-Driven-Development-Firm/ollama-and-langchain.git
    cd ollama-and-langchain

    # Create environment file
    cat > .env << EOF
# Database Configuration
POSTGRES_USER=app
POSTGRES_PASSWORD=secure_password_123
POSTGRES_DB=llm
POSTGRES_DSN=postgresql+psycopg://app:secure_password_123@db:5432/llm

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Ollama Configuration
OLLAMA_BASE_URL=http://ollama-container:11434
OLLAMA_MODELS=jimscard/whiterabbit-neo,thirty3/kali,qwen2.5-coder:7b,nomic-embed-text

# Security Configuration
JWT_SECRET=your-super-secure-jwt-secret-32-chars-min
ADMIN_EMAIL=admin_ibrahim@zyniq.solutions

# OAuth Configuration (Optional)
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRET=

# Monitoring Configuration
PROMETHEUS_MULTIPROC_DIR=/tmp/prom
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=Zyniq@1234567
EOF

    # Create docker-compose override for VM deployment
    cat > docker-compose.override.yml << EOF
version: "3.8"

services:
  ollama:
    container_name: ollama-container
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_MODELS=jimscard/whiterabbit-neo,thirty3/kali,qwen2.5-coder:7b,nomic-embed-text
    volumes:
      - ollama-data:/root/.ollama
    command: ["sh", "-c", "ollama serve & sleep 10 && ollama pull jimscard/whiterabbit-neo && ollama pull thirty3/kali && ollama pull qwen2.5-coder:7b && ollama pull nomic-embed-text && wait"]

  api:
    ports:
      - "8000:8000"
    environment:
      - OLLAMA_BASE_URL=http://ollama-container:11434

  frontend:
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://$(curl -s http://checkip.amazonaws.com):8000

  grafana:
    ports:
      - "3001:3000"

  prometheus:
    ports:
      - "9090:9090"

volumes:
  ollama-data:
EOF

    # Build and start services
    echo "🔨 Building Docker images..."
    docker build -f api/Dockerfile.backend -t ollama-api:latest ./api
    docker build -f frontend/Dockerfile.frontend -t ollama-frontend:latest ./frontend

    # Start all services
    echo "🚀 Starting complete stack..."
    docker-compose up -d

    # Wait for services to start
    sleep 60

    # Pull models manually if needed
    echo "🤖 Ensuring models are downloaded..."
    docker exec ollama-container ollama pull jimscard/whiterabbit-neo
    docker exec ollama-container ollama pull thirty3/kali
    docker exec ollama-container ollama pull qwen2.5-coder:7b
    docker exec ollama-container ollama pull nomic-embed-text

    echo "✅ Complete stack deployment finished!"
    echo "Setup complete marker" > /tmp/full-stack-ready
  '

# Wait for VM to be ready
echo "⏳ Waiting for VM creation and setup..."
sleep 60

# Check VM status
VM_STATUS=$(gcloud compute instances describe ollama-full-stack --zone=$ZONE --format="get(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "RUNNING" ]; then
  VM_IP=$(gcloud compute instances describe ollama-full-stack --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
  
  echo ""
  echo "🎉 VM created successfully!"
  echo "🌐 VM IP: $VM_IP"
  echo ""
  echo "🔗 Access URLs (will be available after setup completes):"
  echo "Frontend:    http://$VM_IP:3000"
  echo "API:         http://$VM_IP:8000"
  echo "Ollama:      http://$VM_IP:11434"
  echo "Grafana:     http://$VM_IP:3001 (admin/Zyniq@1234567)"
  echo "Prometheus:  http://$VM_IP:9090"
  echo ""
  echo "🔧 SSH into VM:"
  echo "gcloud compute ssh ollama-full-stack --zone=$ZONE"
  echo ""
  echo "📊 Check deployment progress:"
  echo "gcloud compute instances get-serial-port-output ollama-full-stack --zone=$ZONE"
  echo ""
  echo "🧪 Test Ollama API:"
  echo "curl -X POST http://$VM_IP:11434/api/generate \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '{\"model\": \"jimscard/whiterabbit-neo\", \"prompt\": \"Hello!\", \"stream\": false}'"
  echo ""
  echo "⏰ Setup takes ~10-15 minutes. Check status with SSH or serial port output."
else
  echo "❌ VM creation failed. Check with:"
  echo "gcloud compute instances describe ollama-full-stack --zone=$ZONE"
fi