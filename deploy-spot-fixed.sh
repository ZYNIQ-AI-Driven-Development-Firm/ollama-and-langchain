#!/bin/bash
set -e

echo "🔧 Fixed Spot Instance Deployment for Ollama"
echo "==========================================="

# Authenticate first
echo "🔐 Authenticating with Google Cloud..."
gcloud auth login --no-launch-browser || echo "Please run: gcloud auth login"

# Set project
gcloud config set project zyniq-core

# Create Spot Instance with correct image and larger disk
echo "🚀 Creating Spot Instance with Ollama..."
gcloud compute instances create-with-container ollama-spot \
  --provisioning-model=SPOT \
  --instance-termination-action=DELETE \
  --machine-type=n1-standard-4 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=200GB \
  --boot-disk-type=pd-ssd \
  --zone=us-central1-a \
  --container-image=ollama/ollama:latest \
  --container-arg="serve" \
  --container-mount-host-path=host-path=/tmp/.ollama,mount-path=/root/.ollama \
  --metadata=startup-script='
    #!/bin/bash
    # Install NVIDIA drivers for GPU support
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o cuda-keyring.deb
    dpkg -i cuda-keyring.deb
    apt-get update
    apt-get install -y cuda-drivers-535 cuda-toolkit-12-2

    # Wait for Ollama to start
    sleep 10

    # Pull models in background
    docker exec $(docker ps -q) ollama pull llama3.1:8b-instruct &
    docker exec $(docker ps -q) ollama pull qwen2.5-coder:7b &
    docker exec $(docker ps -q) ollama pull nomic-embed-text &
  '

# Get instance IP
VM_IP=$(gcloud compute instances describe ollama-spot \
  --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo ""
echo "🎉 Spot Instance created successfully!"
echo ""
echo "🌐 VM IP: $VM_IP"
echo "🔗 Ollama URL: http://$VM_IP:11434"
echo ""
echo "⏳ Models are downloading in background..."
echo "📊 Check status: gcloud compute instances get-serial-port-output ollama-spot --zone=us-central1-a"
echo ""
echo "🧪 Test Ollama:"
echo "curl -X POST http://$VM_IP:11434/api/generate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"llama3.1:8b-instruct\", \"prompt\": \"Hello!\", \"stream\": false}'"
echo ""
echo "💰 Cost: ~\$0.15-0.30/hour (Spot pricing)"
echo "🛑 To stop: gcloud compute instances delete ollama-spot --zone=us-central1-a"