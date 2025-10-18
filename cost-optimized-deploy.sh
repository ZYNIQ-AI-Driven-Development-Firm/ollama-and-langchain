#!/bin/bash
set -e

echo "💰 Cost-Optimized Ollama GPU Deployment"
echo "======================================"

# Configuration for cost optimization
INSTANCE_TYPE=${1:-"n1-standard-4"}  # 4 vCPUs, good balance
GPU_TYPE=${2:-"nvidia-tesla-t4"}    # Cheapest GPU option
GPU_COUNT=${3:-1}
ZONE=${4:-"us-central1-a"}
PROJECT_ID=${5:-"zyniq-core"}

echo "🎯 Configuration:"
echo "Instance: $INSTANCE_TYPE (4 vCPUs, 15GB RAM)"
echo "GPU: $GPU_COUNT x $GPU_TYPE"
echo "Zone: $ZONE"
echo "Estimated cost: ~$0.50-1.00/hour (on-demand)"
echo ""

# Create VM with GPU
echo "🏗️ Creating GPU VM..."
gcloud compute instances create ollama-gpu \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=$INSTANCE_TYPE \
  --accelerator=type=$GPU_TYPE,count=$GPU_COUNT \
  --maintenance-policy=TERMINATE \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-ssd \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --metadata=startup-script="#!/bin/bash
# Install NVIDIA drivers
curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -o cuda-keyring.deb
dpkg -i cuda-keyring.deb
apt-get update
apt-get install -y cuda-drivers-535 cuda-toolkit-12-2

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
systemctl start ollama
systemctl enable ollama

# Pull efficient models
ollama pull llama3.1:8b-instruct
ollama pull qwen2.5-coder:7b
ollama pull nomic-embed-text

echo 'Ollama GPU setup complete!' > /tmp/setup-complete"

# Wait for VM to be ready
echo "⏳ Waiting for VM setup to complete..."
sleep 120

# Get VM external IP
VM_IP=$(gcloud compute instances describe ollama-gpu \
  --zone=$ZONE \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "🌐 VM IP: $VM_IP"
echo "🔗 Ollama URL: http://$VM_IP:11434"
echo ""
echo "💰 Cost breakdown (approximate):"
echo "- VM (n1-standard-4): ~$0.19/hour"
echo "- T4 GPU: ~$0.35/hour"
echo "- SSD Storage: ~$0.04/hour"
echo "- Total: ~$0.58/hour (~$420/month if always on)"
echo ""
echo "🛠️ Test commands:"
echo "curl -X POST http://$VM_IP:11434/api/generate \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"llama3.1:8b-instruct\", \"prompt\": \"Hello!\", \"stream\": false}'"
echo ""
echo "🛑 To stop VM: gcloud compute instances stop ollama-gpu --zone=$ZONE"
echo "🔄 To restart: gcloud compute instances start ollama-gpu --zone=$ZONE"
echo "🗑️ To delete: gcloud compute instances delete ollama-gpu --zone=$ZONE"