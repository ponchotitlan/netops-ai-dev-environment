#!/bin/bash
# devcontainer-init.sh
# Waits for NSO readiness.

set -euo pipefail

MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-120}"

echo "[INFO] Waiting for NSO to be ready (timeout: ${MAX_WAIT_SECONDS}s)"
for ((i=1; i<=MAX_WAIT_SECONDS; i++)); do
    if ncs_cmd -c "wait-start 2" >/dev/null 2>&1; then
        echo "[OK] NSO is ready"
        break
    fi

    if [[ "$i" -eq "$MAX_WAIT_SECONDS" ]]; then
        echo "[ERROR] NSO did not become ready in ${MAX_WAIT_SECONDS}s"
        exit 1
    fi

    sleep 1
done

echo "[OK] NSO readiness check completed"
