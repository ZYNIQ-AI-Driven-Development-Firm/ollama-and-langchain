#!/bin/bash

# Ollama-and-Langchain VM Deployment Script
# Run this on your GPU VM with sudo privileges

set -e

echo "🚀 Starting Ollama-and-Langchain deployment on VM"

# Update system
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
apt-get install -y curl wget git htop nvtop docker.io docker-compose-plugin

# Start Docker service
systemctl start docker
systemctl enable docker

# Install NVIDIA Container Toolkit (if GPU available)
if nvidia-smi &> /dev/null; then
    echo "🎮 Setting up NVIDIA Container Toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update && apt-get install -y nvidia-docker2
    systemctl restart docker
fi

# Clone repository
echo "📥 Cloning repository..."
cd /opt
git clone https://github.com/ZYNIQ-AI-Driven-Development-Firm/ollama-and-langchain.git
cd ollama-and-langchain

# Create .env file with VM-specific configuration
echo "⚙️ Creating environment configuration..."
cat > .env << EOF
# VM Configuration
POSTGRES_DSN=postgresql+psycopg://app:pass@db:5432/llm
REDIS_URL=redis://redis:6379/0
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODELS=llama3.1:8b-instruct,qwen2.5:32b-instruct,qwen2.5-coder:14b,mistral-nemo:12b-instruct,nomic-embed-text

# Security
JWT_SECRET=your-super-secure-jwt-secret-32-chars-min
ADMIN_EMAIL=admin_ibrahim@zyniq.solutions

# OAuth (optional)
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRET=

# Monitoring
PROMETHEUS_MULTIPROC_DIR=/tmp/prom
EOF

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