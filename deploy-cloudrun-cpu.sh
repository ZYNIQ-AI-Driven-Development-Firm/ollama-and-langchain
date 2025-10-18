#!/bin/bash
set -e

echo "☁️ CPU Ollama on Cloud Run (Super Simple)"
echo "========================================"

PROJECT_ID="zyniq-core"
SERVICE_NAME="ollama-cpu-service"
REGION="us-central1"

# Set project
gcloud config set project $PROJECT_ID

# Create Ollama image with CPU models
echo "🏗️ Building CPU-optimized Ollama image..."
cat > Dockerfile.cpu << EOF
FROM ollama/ollama:latest

# Pre-download CPU-efficient models
RUN ollama serve & sleep 5 && \
    ollama pull llama3.1:8b-instruct && \
    ollama pull qwen2.5-coder:7b && \
    ollama pull phi3:14b && \
    ollama pull nomic-embed-text && \
    pkill ollama

EXPOSE 11434
CMD ["ollama", "serve"]
EOF

# Build and push
IMAGE_NAME="gcr.io/$PROJECT_ID/ollama-cpu:latest"
docker build -f Dockerfile.cpu -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 11434 \
  --memory 16Gi \
  --cpu 4 \
  --max-instances 3 \
  --timeout 3600 \
  --concurrency 8

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --format="value(status.url)")

echo ""
echo "🎉 Cloud Run CPU deployment complete!"
echo ""
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "🧪 Test commands:"
echo ""
echo "# Test Llama 3.1"
echo "curl -X POST \"$SERVICE_URL/api/generate\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"llama3.1:8b-instruct\", \"prompt\": \"Explain recursion in simple terms\", \"stream\": false}'"
echo ""
echo "# Test Qwen2.5 Coder"
echo "curl -X POST \"$SERVICE_URL/api/generate\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"qwen2.5-coder:7b\", \"prompt\": \"Write a React component for a todo list\", \"stream\": false}'"
echo ""
echo "# List models"
echo "curl $SERVICE_URL/api/tags"
echo ""
echo "💰 Cost: Pay-per-request (very cheap for light usage)"
echo "⚡ Performance: Good for development/testing, reasonable for light production"
echo ""
echo "🛑 To delete: gcloud run services delete $SERVICE_NAME --region=$REGION"