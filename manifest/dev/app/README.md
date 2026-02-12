# App (Development)

The main application service for Flotio (Development Environment).

## 🛠️ Configuration
- **Image**: `ghcr.io/flotio-dev/app`
- **Port**: 3000
- **Replicas**: 1

## 🔑 Environment Variables
- `NEXT_PUBLIC_API_URL`: URL of the Core API.
- `NEXT_PUBLIC_APP_URL`: Public URL of the App.

## 🚀 Deployment
Deployed to the `dev` namespace via ArgoCD.
