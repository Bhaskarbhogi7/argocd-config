# AKS deployment notes

## Prerequisites

- AKS cluster with Azure Application Routing enabled
- `kubectl` and `helm` installed
- A DNS name for Argo CD, for example `argocd.example.com`
- A TLS certificate and private key for that host

## Create the TLS secret

Replace the placeholder values in [platform-argocd/templates/tls-secret-example.yaml](platform-argocd/templates/tls-secret-example.yaml) and apply it:

```bash
kubectl apply -f platform-argocd/templates/tls-secret-example.yaml
```

## Install Argo CD

```bash
cd platform-argocd
./scripts/install.sh ./environments/prod/values.yaml
```

## Verify

```bash
kubectl get ingress -n argocd
kubectl get pods -n argocd
kubectl get svc -n argocd
```

## Initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
