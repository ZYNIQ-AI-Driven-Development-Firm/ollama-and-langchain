#!/bin/bash

# Ollama-and-Langchain VM Deployment Script
# Run this on your GPU VM with sudo privileges

set -e

echo "🚀 Starting Ollama-and-Langchain deployment on VM"

# Fetch secrets from Google Cloud Secret Manager
echo "🔐 Fetching secrets from Google Cloud Secret Manager..."

# Update system
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
apt-get install -y curl wget git htop nvtop docker.io docker-compose-plugin

# Start Docker service
systemctl start docker
systemctl enable docker

# Install Google Cloud SDK
echo "☁️ Installing Google Cloud SDK..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update && apt-get install -y google-cloud-sdk

# Authenticate with service account (if you have a key file)
# gcloud auth activate-service-account --key-file=/path/to/service-account-key.json

# Or use metadata service for VM-based auth
gcloud auth login --no-launch-browser || true

# Set project
gcloud config set project zyniq-core

# Clone repository
echo "📥 Cloning repository..."
cd /opt
git clone https://github.com/ZYNIQ-AI-Driven-Development-Firm/ollama-and-langchain.git
cd ollama-and-langchain

# Create .env file from Google Cloud secrets
echo "🔐 Fetching secrets from Google Cloud..."
cat > .env << EOF
# VM Configuration
POSTGRES_DSN=$(gcloud secrets versions access latest --secret="POSTGRES_DSN" 2>/dev/null || echo "postgresql+psycopg://app:pass@db:5432/llm")
REDIS_URL=$(gcloud secrets versions access latest --secret="REDIS_URL" 2>/dev/null || echo "redis://redis:6379/0")
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODELS=$(gcloud secrets versions access latest --secret="OLLAMA_MODELS" 2>/dev/null || echo "llama3.1:8b-instruct,qwen2.5:32b-instruct,qwen2.5-coder:14b,mistral-nemo:12b-instruct,nomic-embed-text")

# Security
JWT_SECRET=$(gcloud secrets versions access latest --secret="JWT_SECRET" 2>/dev/null || echo "your-super-secure-jwt-secret-32-chars-min")
ADMIN_EMAIL=$(gcloud secrets versions access latest --secret="ADMIN_EMAIL" 2>/dev/null || echo "admin_ibrahim@zyniq.solutions")

# OAuth (optional)
OAUTH_CLIENT_ID=$(gcloud secrets versions access latest --secret="OAUTH_CLIENT_ID" 2>/dev/null || echo "")
OAUTH_CLIENT_SECRET=$(gcloud secrets versions access latest --secret="OAUTH_CLIENT_SECRET" 2>/dev/null || echo "")

# Monitoring
PROMETHEUS_MULTIPROC_DIR=/tmp/prom
EOF

echo "✅ Environment configuration created from Google Cloud secrets"

# Build Docker images
echo "🔨 Building Docker images..."
docker build -f api/Dockerfile.backend -t ollama-api:latest ./api
docker build -f frontend/Dockerfile.frontend -t ollama-frontend:latest ./frontend
docker build -f Dockerfile.ollama -t ollama-worker:latest .

# Create external network for reverse proxy
docker network create proxy || true

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "📊 Service Status:"
docker-compose ps

# Show access information
echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Access URLs:"
echo "Frontend: http://$(curl -s http://checkip.amazonaws.com):3000"
echo "API: http://$(curl -s http://checkip.amazonaws.com):8000"
echo "Grafana: http://$(curl -s http://checkip.amazonaws.com):3000"
echo ""
echo "🔧 Management Commands:"
echo "View logs: docker-compose logs -f"
echo "Stop services: docker-compose down"
echo "Restart services: docker-compose restart"
echo ""
echo "📝 Next steps:"
echo "1. Update DNS to point to VM IP: $(curl -s http://checkip.amazonaws.com)"
echo "2. Configure firewall rules for ports 80, 443, 3000, 8000"
echo "3. Set up SSL certificates if needed"