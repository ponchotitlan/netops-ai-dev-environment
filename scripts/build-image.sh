#!/bin/bash
# build-image.sh
# Builds the NSO custom Docker image.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/docker-env.sh"

load_env
validate_required_vars NSO_BASE NSO_IMAGE

echo ""
echo "[INFO] Building NSO image"
echo "[INFO] Base image  : ${NSO_BASE}"
echo "[INFO] Target image: ${NSO_IMAGE}"

docker build \
    --build-arg NSO_BASE="${NSO_BASE}" \
    --tag "${NSO_IMAGE}" \
    "${PROJECT_ROOT}"

echo ""
echo "[OK] Build completed: ${NSO_IMAGE}"
