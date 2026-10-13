#!/bin/bash
# nso-load.sh
# Inspects /tmp/nso inside the container and runs ncs_load -l -m for each file.

set -euo pipefail

NSO_LOAD_DIR="/tmp/nso"

echo "[INFO] Inspecting contents of $NSO_LOAD_DIR"

# Check if directory exists
if [[ ! -d "$NSO_LOAD_DIR" ]]; then
    echo "[ERROR] Directory $NSO_LOAD_DIR does not exist"
    exit 1
fi

# Count files in directory
file_count=$(find "$NSO_LOAD_DIR" -maxdepth 1 -type f | wc -l)

if [[ $file_count -eq 0 ]]; then
    echo "[WARN] No files found in $NSO_LOAD_DIR"
    exit 0
fi

echo "[INFO] Found $file_count file(s) to load"

# Loop through each file and run ncs_load
for file in "$NSO_LOAD_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        echo "[INFO] Loading file: $filename"
        
        if ncs_load -l -m "$file"; then
            echo "[OK] Successfully loaded: $filename"
        else
            echo "[ERROR] Failed to load: $filename"
            exit 1
        fi
    fi
done

echo "[INFO] All files loaded successfully"
exit 0
