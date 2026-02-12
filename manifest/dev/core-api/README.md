# Core API (Development)

The backend API service for the Flotio platform (Development Environment).

## 🛠️ Configuration
- **Image**: `ghcr.io/flotio-dev/core-api`
- **Port**: 3000 (Target Port)
- **Replicas**: 1

## 🔑 Environment Variables
This service requires the following environment variables (managed via ConfigMap/Secrets):
- Database Connection String (PostgreSQL)
- Redis URL
- External Service Keys

## 🚀 Deployment
This manifest is deployed via ArgoCD to the `dev` namespace.
