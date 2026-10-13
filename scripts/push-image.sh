#!/bin/bash
# push-image.sh
# Logs in to the registry and pushes the NSO custom Docker image.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/docker-env.sh"

load_env
validate_required_vars NSO_IMAGE DOCKER_REGISTRY DOCKER_REGISTRY_USER DOCKER_REGISTRY_TOKEN

echo ""
echo "[INFO] Logging in to ${DOCKER_REGISTRY} as ${DOCKER_REGISTRY_USER}"
echo "${DOCKER_REGISTRY_TOKEN}" | docker login "${DOCKER_REGISTRY}" \
    -u "${DOCKER_REGISTRY_USER}" --password-stdin

echo ""
echo "[INFO] Pushing image ${NSO_IMAGE}"
docker push "${NSO_IMAGE}"

echo ""
echo "[OK] Push completed: ${NSO_IMAGE}"
