#!/bin/bash
# Quick deployment script for Google Cloud
# Usage: ./build-and-deploy.sh PROJECT_ID REGION

set -e

PROJECT_ID=${1}
REGION=${2:-"us-central1"}

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 PROJECT_ID [REGION]"
    echo "Example: $0 my-gcp-project us-central1"
    exit 1
fi

echo "🚀 Building and deploying to Google Cloud"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

# Set project
gcloud config set project $PROJECT_ID

# Build images with Cloud Build
echo "🔨 Building images with Cloud Build..."
gcloud builds submit --config cloudbuild.yaml .

# Tag images for Cloud Run
API_IMAGE="gcr.io/$PROJECT_ID/ollama-api:latest"
FRONTEND_IMAGE="gcr.io/$PROJECT_ID/ollama-frontend:latest"
OLLAMA_IMAGE="gcr.io/$PROJECT_ID/ollama:latest"

echo "✅ Images built successfully!"
echo "API Image: $API_IMAGE"
echo "Frontend Image: $FRONTEND_IMAGE"
echo "Ollama Image: $OLLAMA_IMAGE"

echo ""
echo "🌐 Next steps:"
echo "1. Create Cloud SQL and Redis instances"
echo "2. Deploy to Cloud Run using the deployment guide"
echo "3. Configure environment variables"
echo ""
echo "📚 See deploy/gcp-cloud-run.md for detailed instructions"