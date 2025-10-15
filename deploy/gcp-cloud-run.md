# Google Cloud Run Deployment

This document outlines the steps to deploy the Ollama Provider Stack to Google Cloud Run.

## Prerequisites

1.  A Google Cloud Platform (GCP) project.
2.  `gcloud` CLI installed and authenticated.
3.  A Cloud SQL for PostgreSQL instance.
4.  A Memorystore for Redis instance.

## Configuration

1.  **Enable APIs**
    Enable the Cloud Run, Cloud Build, and Container Registry APIs in your GCP project.

2.  **Create a Service Account**
    Create a service account with the following roles:
    *   Cloud Run Admin
    *   Storage Admin
    *   Cloud SQL Client

3.  **Store Secrets in GitHub**
    Add the following secrets to your GitHub repository:
    *   `GCP_PROJECT_ID`: Your GCP project ID.
    *   `GCP_REGION`: The region for your Cloud Run services (e.g., `us-central1`).
    *   `GCP_SA_KEY`: The JSON key for the service account you created.
    *   `POSTGRES_DSN`: The connection string for your Cloud SQL instance.
    *   `REDIS_URL`: The connection string for your Redis instance.
    *   `JWT_SECRET`: A secret key for JWTs.
    *   `OAUTH_CLIENT_ID`: Your OAuth client ID.
    *   `OAUTH_CLIENT_SECRET`: Your OAuth client secret.
    *   `OLLAMA_MODELS`: Comma-separated list of Ollama models to pull.

## Deployment

The included GitHub Actions workflow will automatically build and deploy the services to Cloud Run when you push to the `main` branch.

## Persistent Storage

*   **PostgreSQL**: By using a Cloud SQL instance, your database will be persistent across deployments.
*   **Redis**: By using a Memorystore instance, your Redis cache will be persistent.
*   **Ollama Models**: The models are pulled on startup of the `ollama` service, so they are not persistent in the same way as the databases. For true persistence, you would need to use a persistent volume, which is not directly supported in the same way on Cloud Run as it is with Docker volumes. A common pattern is to use a Cloud Storage bucket to store the models and download them on startup if they don't exist. The current setup re-pulls them on each deployment.
