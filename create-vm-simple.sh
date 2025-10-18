#!/bin/bash
set -e

echo "🚀 Creating CPU VM for Ollama"
echo "============================="

# Create VM with Ollama pre-installed
gcloud compute instances create ollama-cpu \
  --machine-type=n2-highmem-8 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=200GB \
  --boot-disk-type=pd-ssd \
  --zone=us-central1-a \
  --metadata=startup-script='#!/bin/bash
    set -e
    echo "Setting up Ollama on VM..."

    # Update system
    apt-get update

    # Install Docker
    apt-get install -y docker.io curl
    systemctl start docker
    systemctl enable docker

    # Install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh

    # Start Ollama
    systemctl start ollama
    systemctl enable ollama

    # Pull models
    sleep 5
    ollama pull jimscard/whiterabbit-neo &
    ollama pull thirty3/kali &
    ollama pull qwen2.5-coder:7b &
    ollama pull nomic-embed-text &

    echo "Ollama setup complete!" > /tmp/setup-done
  '

echo "⏳ VM is being created... This will take 2-3 minutes."

# Wait for VM to be ready
sleep 30

# Check VM status
VM_STATUS=$(gcloud compute instances describe ollama-cpu --zone=us-central1-a --format="get(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "RUNNING" ]; then
  VM_IP=$(gcloud compute instances describe ollama-cpu --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
  echo ""
  echo "✅ VM created successfully!"
  echo "🌐 VM IP: $VM_IP"
  echo ""
  echo "🔗 Next steps:"
  echo "1. SSH into VM: gcloud compute ssh ollama-cpu --zone=us-central1-a"
  echo "2. Check setup: cat /tmp/setup-done"
  echo "3. Test Ollama: curl http://localhost:11434/api/tags"
else
  echo "❌ VM creation failed or still in progress. Check status with:"
  echo "gcloud compute instances describe ollama-cpu --zone=us-central1-a"
fi