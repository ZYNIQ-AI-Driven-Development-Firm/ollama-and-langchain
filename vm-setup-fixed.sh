#!/bin/bash
set -e

echo "🔧 Installing dependencies on zyniq-llm-provider..."

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker and basic packages
sudo apt-get install -y \
  docker.io \
  curl \
  wget \
  git \
  htop \
  build-essential \
  python3-pip \
  nodejs \
  npm \
  ca-certificates \
  gnupg \
  lsb-release

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose (latest version)
echo "📦 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for docker-compose command
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version

# Install Ollama
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl start ollama
sudo systemctl enable ollama

# Clone the repository
echo "📥 Cloning repository..."
cd /home/$USER
if [ -d "ollama-and-langchain" ]; then
  cd ollama-and-langchain
  git pull
else
  git clone https://github.com/ZYNIQ-AI-Driven-Development-Firm/ollama-and-langchain.git
  cd ollama-and-langchain
fi

# Create environment file for VM deployment
echo "⚙️ Creating environment configuration..."
cat > .env << 'ENVEOF'
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

# Pre-download Ollama models (to avoid Docker timeout)
echo "🤖 Pre-downloading Ollama models..."
ollama pull jimscard/whiterabbit-neo &
ollama pull thirty3/kali &
ollama pull qwen2.5-coder:7b &
ollama pull nomic-embed-text &

# Build Docker images while models download
echo "🔨 Building Docker images..."
sudo docker build -f api/Dockerfile.backend -t ollama-api:latest ./api &
sudo docker build -f frontend/Dockerfile.frontend -t ollama-frontend:latest ./frontend &

# Wait for model downloads and builds to complete
echo "⏳ Waiting for models and builds to complete..."
wait

# Start services with new docker group (need to re-login for group to take effect)
echo "🚀 Starting complete stack..."
newgrp docker << 'DOCKEREOF'
docker-compose up -d
DOCKEREOF

# Alternative: use sudo if newgrp doesn't work
if [ $? -ne 0 ]; then
  echo "🔄 Fallback: Using sudo for docker-compose..."
  sudo docker-compose up -d
fi

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 90

# Check service status
echo "📊 Service Status:"
sudo docker-compose ps

# Get external IP
EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com || curl -s http://ipinfo.io/ip || echo "localhost")

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
echo "docker-compose logs -f           # View logs"
echo "docker-compose restart          # Restart services"
echo "docker-compose down             # Stop services"
echo "docker-compose up -d            # Start services"
echo ""
echo "📝 Notes:"
echo "- You may need to logout and login again for docker group permissions"
echo "- If docker commands need sudo, the setup will handle it automatically"
echo ""
echo "✅ Setup complete!"