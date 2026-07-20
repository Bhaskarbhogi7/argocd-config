# platform-argocd

This chart scaffold provides a starting point for deploying Argo CD on Azure AKS with environment-specific values and supporting Kubernetes resources.

## Structure

- templates/: Kubernetes manifests for namespace, ingress, network policy, Azure workload identity, and Argo CD project
- environments/: values files for dev, nonprod, and prod

## Quick start

```bash
helm upgrade --install argocd ./platform-argocd \
  -f ./platform-argocd/values.yaml \
  -f ./platform-argocd/environments/dev/values.yaml
```

Replace the example hostnames in the values files before deploying.
