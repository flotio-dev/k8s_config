# ArgoCD Applications

This directory contains the ArgoCD Application resources that define how the GitOps process works for Flotio.

## 📄 Application Manifests

- **applications-prod.yaml**: Defines the `Application` resources for the production environment. Points to `manifest/prod` paths.
- **application.yaml**: Defines the `Application` resources for the development environment (naming convention might vary). Points to `manifest/dev` paths.

## 🔄 Sync Policy

- **Automated Sync**: Most applications are configured to automatically sync when changes are detected in the git repository.
- **Pruning**: Resources deleted from git will be removed from the cluster (if `prune: true` is set).
- **Self-Heal**: ArgoCD attempts to correct drift if the cluster state deviates from git.

## 📦 Bootstrapping

To apply these applications to a new ArgoCD instance:

```bash
kubectl apply -f argocd/applications-prod.yaml
```
