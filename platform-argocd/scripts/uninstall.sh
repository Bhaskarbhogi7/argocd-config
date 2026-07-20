#!/usr/bin/env bash
set -euo pipefail

helm uninstall argocd || true
