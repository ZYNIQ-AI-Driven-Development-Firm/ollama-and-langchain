# Google Cloud Run Deployment

This guide covers deploying the ollama-and-langchain stack to Google Cloud Run for a serverless, scalable deployment.

## Prerequisites

1. Google Cloud Project with billing enabled
2. `gcloud` CLI installed and authenticated
3. Docker installed locally (for building images)

## Architecture

- **API Backend**: Cloud Run service with auto-scaling
- **Frontend**: Cloud Run service serving Next.js app
- **Ollama**: Cloud Run service with GPU support (when available)
- **Database**: Cloud SQL PostgreSQL instance
- **Cache**: Memorystore Redis instance
- **Load Balancer**: Cloud Load Balancer with CDN

## Deployment Steps

### 1. Build and Push Images

```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Build and push images using Cloud Build
gcloud builds submit --config cloudbuild.yaml .
```

### 2. Create Managed Services

```bash
# Create Cloud SQL instance
gcloud sql instances create ollama-postgres \
    --database-version=POSTGRES_16 \
    --tier=db-g1-small \
    --region=us-central1 \
    --root-password=your-secure-password

# Create database
gcloud sql databases create llm --instance=ollama-postgres

# Create Redis instance
gcloud redis instances create ollama-redis \
    --size=1 \
    --region=us-central1
```

### 3. Deploy Cloud Run Services

```bash
# Deploy API Backend
gcloud run deploy ollama-api \
    --image=gcr.io/$PROJECT_ID/ollama-api:latest \
    --platform=managed \
    --region=us-central1 \
    --allow-unauthenticated \
    --memory=2Gi \
    --cpu=2 \
    --max-instances=10 \
    --set-env-vars="POSTGRES_DSN=postgresql+psycopg://postgres:password@/llm?host=/cloudsql/$PROJECT_ID:us-central1:ollama-postgres,REDIS_URL=redis://redis-ip:6379/0,OLLAMA_BASE_URL=https://ollama-service-url,JWT_SECRET=your-jwt-secret,ADMIN_EMAIL=admin@yourcompany.com" \
    --add-cloudsql-instances=$PROJECT_ID:us-central1:ollama-postgres

# Deploy Frontend
gcloud run deploy ollama-frontend \
    --image=gcr.io/$PROJECT_ID/ollama-frontend:latest \
    --platform=managed \
    --region=us-central1 \
    --allow-unauthenticated \
    --memory=1Gi \
    --cpu=1 \
    --max-instances=20 \
    --set-env-vars="NEXT_PUBLIC_API_URL=https://ollama-api-service-url"

# Deploy Ollama (with GPU when available)
gcloud run deploy ollama \
    --image=gcr.io/$PROJECT_ID/ollama:latest \
    --platform=managed \
    --region=us-central1 \
    --allow-unauthenticated \
    --memory=8Gi \
    --cpu=4 \
    --max-instances=3 \
    --gpu=1 \
    --gpu-type=nvidia-l4 \
    --set-env-vars="OLLAMA_MODELS=jimscard/whiterabbit-neo,thirty3/kali"
```

## Environment Variables

Create a `.env.production` file:

```bash
# Database
POSTGRES_DSN=postgresql+psycopg://postgres:password@/llm?host=/cloudsql/PROJECT_ID:REGION:INSTANCE

# Redis
REDIS_URL=redis://REDIS_IP:6379/0

# Ollama
OLLAMA_BASE_URL=https://ollama-SERVICE_URL
OLLAMA_MODELS=jimscard/whiterabbit-neo,thirty3/kali,qwen2.5:32b-instruct

# Security
JWT_SECRET=your-super-secure-jwt-secret
ADMIN_EMAIL=admin@yourcompany.com

# OAuth (if using)
OAUTH_CLIENT_ID=your-oauth-client-id
OAUTH_CLIENT_SECRET=your-oauth-client-secret

# Frontend
NEXT_PUBLIC_API_URL=https://your-api-domain.com
```

## Scaling Configuration

### API Backend
- **CPU**: 2 vCPU (adjust based on load)
- **Memory**: 2 GiB (for FastAPI + ML libraries)
- **Concurrency**: 80 requests per instance
- **Max instances**: 10 (adjust based on expected traffic)

### Frontend
- **CPU**: 1 vCPU
- **Memory**: 1 GiB
- **Concurrency**: 100 requests per instance
- **Max instances**: 20

### Ollama Service
- **CPU**: 4 vCPU
- **Memory**: 8 GiB (minimum for LLM inference)
- **GPU**: 1x NVIDIA L4 (when available)
- **Max instances**: 3 (expensive, limit based on budget)

## Cost Optimization

1. **Use preemptible instances** for development
2. **Set up budget alerts** in Google Cloud Console
3. **Enable auto-scaling** to scale to zero during low usage
4. **Use Cloud CDN** for static assets
5. **Monitor usage** with Cloud Monitoring

## Monitoring

Deploy monitoring stack separately or use Google Cloud's managed services:

```bash
# Enable Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Create uptime checks
gcloud alpha monitoring uptime create check-api \
    --display-name="API Health Check" \
    --http-check-path="/health" \
    --hostname=your-api-domain.com

gcloud alpha monitoring uptime create check-frontend \
    --display-name="Frontend Health Check" \
    --http-check-path="/" \
    --hostname=your-frontend-domain.com
```

## Security

1. **Enable Identity-Aware Proxy** for admin endpoints
2. **Use Secret Manager** for sensitive environment variables
3. **Enable Cloud Armor** for DDoS protection
4. **Set up VPC** for private communication between services

## Troubleshooting

```bash
# View logs
gcloud logs tail projects/$PROJECT_ID/logs/run.googleapis.com%2Fstdout

# Debug a specific service
gcloud run services describe ollama-api --region=us-central1

# Test Cloud SQL connection
gcloud sql connect ollama-postgres --user=postgres

# Test Redis connection
gcloud redis instances describe ollama-redis --region=us-central1
```
