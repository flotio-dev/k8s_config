# k8s_config

Centralized repository for Kubernetes configuration manifests and ArgoCD applications for the **flotio** project.

## 📂 Repository Structure

- **`manifest/`**: Contains raw Kubernetes manifests (Deployments, Services, ConfigMaps, etc.) organized by environment.
  - **`prod/`**: Production environment manifests.
  - **`dev/`**: Development environment manifests.
- **`argocd/`**: ArgoCD Application manifests that sync the `manifest/` directory to the cluster.
- **`CI/`**: CI/CD pipeline configurations (e.g., GitHub Actions workflows).

## 🚀 Deployment

This repository controls deployments via a GitOps workflow using **ArgoCD**.

1.  **Commit changes** to the `manifest/` directory (e.g., update image tags in `deploy-app.yaml`).
2.  **ArgoCD** detects the changes in the git repository.
3.  **Sync** the application in ArgoCD to apply the new state to the Kubernetes cluster.

### Manual Deployment (Optional)

You can also apply manifests directly using `kubectl`:

```bash
kubectl apply -k manifest/prod/app
```

## 🔐 Secrets

Secrets are managed externally or sealed. Do not commit base64 encoded secrets directly to this repository unless they are non-sensitive or encrypted.
