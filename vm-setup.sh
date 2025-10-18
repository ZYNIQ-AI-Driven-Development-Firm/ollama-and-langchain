#!/bin/bash
set -e

echo "🔧 Installing dependencies on zyniq-llm-provider..."

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker and Docker Compose
sudo apt-get install -y \
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
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose standalone
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl start ollama
sudo systemctl enable ollama

# Clone the repository
cd /home/$USER
git clone https://github.com/ZYNIQ-AI-Driven-Development-Firm/ollama-and-langchain.git
cd ollama-and-langchain

# Create environment file for VM deployment
cat > .env << ENVEOF
# Database Configuration
POSTGRES_USER=app
POSTGRES_PASSWORD=secure_password_123
POSTGRES_DB=llm
POSTGRES_DSN=postgresql+psycopg://app:secure_password_123@db:5432/llm

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Ollama Configuration
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODELS=jimscard/whiterabbit-neo,thirty3/kali,qwen2.5-coder:7b,nomic-embed-text

# Security Configuration
JWT_SECRET=your-super-secure-jwt-secret-32-chars-min-vm
ADMIN_EMAIL=admin_ibrahim@zyniq.solutions

# OAuth Configuration (Optional)
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRET=

# Monitoring Configuration
PROMETHEUS_MULTIPROC_DIR=/tmp/prom
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=Zyniq@1234567
ENVEOF

# Build Docker images
echo "🔨 Building Docker images..."
sudo docker build -f api/Dockerfile.backend -t ollama-api:latest ./api
sudo docker build -f frontend/Dockerfile.frontend -t ollama-frontend:latest ./frontend

# Pull models first (to avoid timeout during startup)
echo "🤖 Pre-downloading Ollama models..."
ollama pull jimscard/whiterabbit-neo &
ollama pull thirty3/kali &
ollama pull qwen2.5-coder:7b &
ollama pull nomic-embed-text &

# Wait for some models to finish
wait

# Start services
echo "🚀 Starting complete stack..."
sudo docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 60

# Check service status
echo "📊 Service Status:"
sudo docker-compose ps

# Get external IP
EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com)

echo ""
echo "🎉 Complete Stack Deployed Successfully!"
echo ""
echo "🌐 Access URLs:"
echo "Frontend:    http://$EXTERNAL_IP:3000"
echo "API:         http://$EXTERNAL_IP:8000"
echo "Ollama:      http://$EXTERNAL_IP:11434"
echo "Grafana:     http://$EXTERNAL_IP:3001 (admin/Zyniq@1234567)"
echo "Prometheus:  http://$EXTERNAL_IP:9090"
echo ""
echo "🧪 Test Ollama:"
echo "curl -X POST http://$EXTERNAL_IP:11434/api/generate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"jimscard/whiterabbit-neo\", \"prompt\": \"Hello! Write a Python function\", \"stream\": false}'"
echo ""
echo "🛠️ Management Commands:"
echo "sudo docker-compose logs -f           # View logs"
echo "sudo docker-compose restart          # Restart services"
echo "sudo docker-compose down             # Stop services"
echo "sudo docker-compose up -d            # Start services"
echo ""
echo "✅ Setup complete!"
