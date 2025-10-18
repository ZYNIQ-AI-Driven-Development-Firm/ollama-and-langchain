#!/bin/bash
set -e

echo "🚀 Simple Ollama Deployment on Google Cloud"
echo "=========================================="

# Install Docker if not already installed
echo "📦 Installing Docker..."
apt-get update
apt-get install -y docker.io curl

# Start Docker service
systemctl start docker || service docker start
systemctl enable docker || true

# Pull Ollama official image
echo "🐳 Pulling Ollama official image..."
docker pull ollama/ollama:latest

# Run Ollama container with persistent volume
echo "🏃 Starting Ollama container..."
docker run -d \
  --name ollama \
  -p 11434:11434 \
  -v ollama-data:/root/.ollama \
  --restart unless-stopped \
  ollama/ollama:latest

# Wait for Ollama to start
echo "⏳ Waiting for Ollama to start..."
sleep 10

# Pull a good coding and conversation model
echo "🤖 Pulling WhiteRabbit Neo model (great for coding & conversation)..."
docker exec ollama ollama pull jimscard/whiterabbit-neo

# Optional: Pull additional models
echo "📚 Pulling additional useful models..."
docker exec ollama ollama pull thirty3/kali &
docker exec ollama ollama pull qwen2.5-coder:7b &
docker exec ollama ollama pull nomic-embed-text &

# Wait for model downloads
wait

# Create a simple test script
cat > test-ollama.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing Ollama installation..."

# Test basic connectivity
echo "Testing basic API..."
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "jimscard/whiterabbit-neo", "prompt": "Hello! Can you help me with coding?", "stream": false}' \
  | jq -r '.response' 2>/dev/null || echo "Response received (jq not available)"

echo ""
echo "✅ Ollama is running!"
echo ""
echo "🌐 Access Ollama at:"
echo "Local: http://localhost:11434"
echo "External: http://$(curl -s http://checkip.amazonaws.com):11434"
echo ""
echo "📖 Available models:"
curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null || echo "Install jq to see model list"
echo ""
echo "🛠️  Usage examples:"
echo "curl -X POST http://localhost:11434/api/generate -H 'Content-Type: application/json' -d '{\"model\": \"jimscard/whiterabbit-neo\", \"prompt\": \"Write a Python function to reverse a string\", \"stream\": false}'"
echo ""
echo "🛑 To stop: docker stop ollama"
echo "🔄 To restart: docker start ollama"
EOF

chmod +x test-ollama.sh

# Run the test
echo "🧪 Running test..."
./test-ollama.sh

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Test the API with: ./test-ollama.sh"
echo "2. Access from your local machine using the external IP"
echo "3. Consider setting up a reverse proxy (nginx/caddy) for production"
echo "4. Add firewall rules to restrict access if needed"