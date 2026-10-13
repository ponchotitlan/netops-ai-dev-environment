#!/bin/bash
# compile-packages.sh
# Compiles all service packages from /nso/run/packages.

set -euo pipefail

# compile_package <package_src_dir>
# Runs `make clean all` in the provided package src directory.
# Fails the script if compilation returns a non-zero exit code.
compile_package(){
    local package_src_dir="$1"
    local package_name
    package_name="$(basename "$(dirname "${package_src_dir}")")"

    echo "[INFO] Compiling package ${package_name}"
    (
        set +u
        source /etc/profile
        set -u
        cd "${package_src_dir}"
        make clean all
    )
}

PACKAGE_DIR="/nso/run/packages"

echo "[INFO] Compiling service packages from ${PACKAGE_DIR}"

shopt -s nullglob
for package_src in "${PACKAGE_DIR}"/*/src; do
    if [[ -d "${package_src}" ]]; then
        compile_package "${package_src}"
    fi
done
shopt -u nullglob

echo "[OK] Package compilation completed"