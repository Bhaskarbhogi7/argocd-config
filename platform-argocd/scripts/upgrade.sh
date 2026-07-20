#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-environments/dev/values.yaml}"
NAMESPACE="argocd"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Unable to reach the Kubernetes cluster. Ensure kubeconfig is configured correctly." >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade argocd . \
  --namespace "$NAMESPACE" \
  -f values.yaml \
  -f "$ENV_FILE"
