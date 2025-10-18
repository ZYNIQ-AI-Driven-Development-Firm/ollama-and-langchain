#!/bin/bash
set -e

echo "🚀 Ollama CPU Deployment (No GPU Required)"
echo "=========================================="

PROJECT_ID=${1:-"zyniq-core"}
SERVICE_NAME="ollama-cpu-service"
REGION=${2:-"us-central1"}

# Set project
gcloud config set project $PROJECT_ID

# Build Ollama image with CPU-optimized models
echo "🏗️  Building Ollama CPU image..."

# Create Dockerfile for CPU deployment
cat > Dockerfile.cpu << EOF
FROM ollama/ollama:latest

# Pre-download CPU-friendly models
RUN ollama serve & sleep 5 && \
    ollama pull llama3.1:8b-instruct && \
    ollama pull qwen2.5-coder:7b && \
    ollama pull nomic-embed-text && \
    pkill ollama

# Expose port
EXPOSE 11434

# Start Ollama
CMD ["ollama", "serve"]
EOF

# Build and push to GCR
IMAGE_NAME="gcr.io/$PROJECT_ID/ollama-cpu:latest"
docker build -f Dockerfile.cpu -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Deploy to Cloud Run with higher resources
echo "🚀 Deploying to Cloud Run (CPU)..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 11434 \
  --memory 16Gi \
  --cpu 4 \
  --max-instances 5 \
  --timeout 3600 \
  --concurrency 4

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "🎉 CPU Deployment Complete!"
echo ""
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "💰 Cost: ~$0.15/hour (much cheaper than GPU!)"
echo ""
echo "🧪 Test commands:"
echo "curl -X POST \"$SERVICE_URL/api/generate\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"llama3.1:8b-instruct\", \"prompt\": \"Write a Python hello world\", \"stream\": false}'"
echo ""
echo "📊 Performance Notes:"
echo "- CPU inference is slower than GPU but works great for development"
echo "- Llama 3.1 8B responds in 5-15 seconds per query"
echo "- Perfect for prototyping and light usage"
echo ""
echo "🔄 Upgrade to GPU later:"
echo "1. Request GPU quota increase in Google Cloud Console"
echo "2. Redeploy with GPU-enabled configuration"