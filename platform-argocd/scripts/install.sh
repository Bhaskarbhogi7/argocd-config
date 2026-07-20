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

TMP_DIR="$(mktemp -d)"
WORK_DIR="$TMP_DIR/chart"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$WORK_DIR"
cp -R "$CHART_DIR"/. "$WORK_DIR"/

python3 - "$WORK_DIR/Chart.yaml" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit(0)
text = path.read_text()
if 'dependencies:' not in text:
    raise SystemExit(0)
lines = text.splitlines()
out = []
in_deps = False
parent_indent = None
for line in lines:
    if not in_deps and line.startswith('dependencies:'):
        in_deps = True
        parent_indent = len(line) - len(line.lstrip())
        continue
    if in_deps:
        indent = len(line) - len(line.lstrip())
        if line.strip() == '':
            out.append(line)
            continue
        if indent <= parent_indent:
            in_deps = False
            out.append(line)
        continue
    out.append(line)
path.write_text('\n'.join(out).rstrip() + '\n')
PY

cd "$WORK_DIR"

echo "Using chart directory: $WORK_DIR"
echo "Using values file: $ENV_FILE"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Unable to reach the Kubernetes cluster. Ensure kubeconfig is configured correctly." >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install argocd . \
  --namespace "$NAMESPACE" \
  --create-namespace \
  -f values.yaml \
  -f "$ENV_FILE"
