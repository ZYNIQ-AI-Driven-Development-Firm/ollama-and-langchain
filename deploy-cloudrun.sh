#!/bin/bash
set -e

echo "☁️  Ollama Cloud Run Deployment (CPU)"
echo "===================================="

PROJECT_ID=${1:-"zyniq-core"}
SERVICE_NAME="ollama-service"
REGION=${2:-"us-central1"}

# Set project
gcloud config set project $PROJECT_ID

# Build and push Ollama image with pre-loaded models
echo "🏗️  Building Ollama image with models..."

# Create Dockerfile for Cloud Run
cat > Dockerfile.cloudrun << EOF
FROM ollama/ollama:latest

# Pre-download models
RUN ollama serve & sleep 5 && \
    ollama pull jimscard/whiterabbit-neo && \
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
docker build -f Dockerfile.cloudrun -t $IMAGE_NAME .
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 11434 \
  --memory 8Gi \
  --cpu 2 \
  --max-instances 3 \
  --timeout 3600 \
  --concurrency 8

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "🧪 Test commands:"
echo "curl -X POST \"$SERVICE_URL/api/generate\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"model\": \"jimscard/whiterabbit-neo\", \"prompt\": \"Write a hello world in Python\", \"stream\": false}'"
echo ""
echo "📖 Available models:"
echo "curl \"$SERVICE_URL/api/tags\""
echo ""
echo "💡 Models included:"
echo "- jimscard/whiterabbit-neo (great for coding & conversation)"
echo "- qwen2.5-coder:7b (excellent for coding)"
echo "- nomic-embed-text (for embeddings)"
echo ""
echo "⚡ This uses CPU inference - good for development/testing"
echo "🔄 For GPU acceleration, use VM deployment instead"