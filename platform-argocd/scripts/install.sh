#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${1:-environments/dev/values.yaml}"
NAMESPACE="argocd"

if [[ "$ENV_FILE" != /* ]]; then
  if [[ -f "$CHART_DIR/$ENV_FILE" ]]; then
    ENV_FILE="$CHART_DIR/$ENV_FILE"
  elif [[ -f "$ENV_FILE" ]]; then
    ENV_FILE="$(cd "$(dirname "$ENV_FILE")" && pwd)/$(basename "$ENV_FILE")"
  fi
fi

cd "$CHART_DIR"

echo "Using chart directory: $CHART_DIR"
echo "Using values file: $ENV_FILE"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Unable to reach the Kubernetes cluster. Ensure kubeconfig is configured correctly." >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace "$NAMESPACE" \
  --create-namespace \
  -f values.yaml \
  -f "$ENV_FILE" \
  --wait --timeout 15m
