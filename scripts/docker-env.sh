#!/bin/bash
# docker-env.sh
# Shared helpers for loading .env and validating required variables.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
ENV_FILE="${PROJECT_ROOT}/.env"

# load_env
# Loads key=value pairs from .env into the current shell session.
# Exits with an error if .env does not exist.
load_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[ERROR] .env file not found at $ENV_FILE"
        exit 1
    fi

    set -a
    eval "$(grep '^[A-Z_][A-Z_0-9]*=' "$ENV_FILE")"
    set +a
}

# validate_required_vars <VAR_NAME...>
# Ensures each provided variable name is set and non-empty.
# Exits on the first missing variable.
validate_required_vars() {
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            echo "[ERROR] Required variable '$var' is not set in .env"
            exit 1
        fi
    done
}
