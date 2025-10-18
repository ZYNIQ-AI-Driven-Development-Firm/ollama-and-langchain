#!/bin/bash
set -e

echo "🚀 CPU-Powered Ollama Deployment (No GPU Required)"
echo "================================================"

# Authenticate and set project
gcloud auth login --no-launch-browser || echo "Please run: gcloud auth login"
gcloud config set project zyniq-core

# Create CPU VM with high memory for better performance
echo "🏗️ Creating high-memory CPU VM..."
gcloud compute instances create ollama-cpu \
  --machine-type=n2-highmem-8 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=200GB \
  --boot-disk-type=pd-ssd \
  --zone=us-central1-a \
  --metadata=startup-script='
    #!/bin/bash
    set -e

    # Update system
    apt-get update && apt-get upgrade -y

    # Install Docker
    apt-get install -y docker.io curl
    systemctl start docker
    systemctl enable docker

    # Install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh

    # Start Ollama service
    systemctl start ollama
    systemctl enable ollama

    # Wait for Ollama to start
    sleep 5

    # Pull efficient CPU-optimized models
    echo "🤖 Pulling CPU-optimized models..."
    ollama pull llama3.1:8b-instruct      # Excellent for coding & conversation
    ollama pull qwen2.5-coder:7b          # Great for programming
    ollama pull phi3:14b                  # Fast and capable
    ollama pull nomic-embed-text          # For embeddings

    echo "✅ CPU Ollama setup complete!"
  '

# Wait for setup to complete
echo "⏳ Waiting for VM setup and model downloads..."
sleep 180

# Get VM IP
VM_IP=$(gcloud compute instances describe ollama-cpu \
  --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo ""
echo "🎉 CPU Ollama VM deployed successfully!"
echo ""
echo "🌐 VM IP: $VM_IP"
echo "🔗 Ollama URL: http://$VM_IP:11434"
echo ""
echo "💰 Cost: ~\$0.30/hour (much cheaper than GPU!)"
echo ""
echo "🧪 Test your models:"
echo ""
echo "# Test Llama 3.1 (best for coding & conversation)"
echo "curl -X POST http://$VM_IP:11434/api/generate \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '\''{\"model\": \"llama3.1:8b-instruct\", \"prompt\": \"Write a Python function to calculate fibonacci\", \"stream\": false}'\''"
echo ""
echo "# Test Qwen2.5 Coder (excellent for programming)"
echo "curl -X POST http://$VM_IP:11434/api/generate \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '\''{\"model\": \"qwen2.5-coder:7b\", \"prompt\": \"Debug this Python code: def hello(): print('hello')\", \"stream\": false}'\''"
echo ""
echo "# List available models"
echo "curl http://$VM_IP:11434/api/tags"
echo ""
echo "🛑 Management commands:"
echo "Stop VM: gcloud compute instances stop ollama-cpu --zone=us-central1-a"
echo "Start VM: gcloud compute instances start ollama-cpu --zone=us-central1-a"
echo "Delete VM: gcloud compute instances delete ollama-cpu --zone=us-central1-a"