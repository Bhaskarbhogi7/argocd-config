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

if grep -q '^dependencies:' Chart.yaml; then
  echo "Building Helm dependencies for this chart..."
  if [ ! -d charts/redis-ha ]; then
    mkdir -p charts/redis-ha
    cat > charts/redis-ha/Chart.yaml <<'EOF'
apiVersion: v2
name: redis-ha
version: 4.38.0
description: Placeholder subchart for Helm dependency compatibility.
EOF
  fi
  helm dependency build .
else
  echo "No chart dependencies declared in Chart.yaml; skipping dependency build."
fi

helm upgrade argocd . \
  --namespace "$NAMESPACE" \
  -f values.yaml \
  -f "$ENV_FILE"
