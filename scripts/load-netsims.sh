#!/bin/bash
# load-netsims.sh
# Creates netsim devices from nso-lab-topology.yaml, starts them,
# loads their config into NSO, then connects and syncs all devices.

set -euo pipefail

# Resolve topology file without requiring TOPOLOGY_FILE to be exported.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TOPOLOGY_FILE_CONTAINER="/tmp/nso-lab-topology.yaml"
DEFAULT_TOPOLOGY_FILE_LOCAL="${SCRIPT_DIR}/../nso-lab-topology.yaml"
TOPOLOGY_FILE="${TOPOLOGY_FILE:-}"

if [[ -z "$TOPOLOGY_FILE" ]]; then
    if [[ -f "$DEFAULT_TOPOLOGY_FILE_CONTAINER" ]]; then
        TOPOLOGY_FILE="$DEFAULT_TOPOLOGY_FILE_CONTAINER"
    else
        TOPOLOGY_FILE="$DEFAULT_TOPOLOGY_FILE_LOCAL"
    fi
fi

NETSIM_DIR="/netsim"
PACKAGES_DIR="/opt/ncs/packages"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

if [[ ! -f "$TOPOLOGY_FILE" ]]; then
    echo "[ERROR] Topology file not found: $TOPOLOGY_FILE"
    exit 1
fi

# parse_topology
# Parses nso-lab-topology.yaml and outputs "<package_name> <netsim_name>" per netsim.
# Package name is derived as "<ned>-<major>.<minor>" from the ned_version field.
parse_topology() {
    awk '
        /^  [a-zA-Z]/ { ned = $1; sub(/:$/, "", ned) }
        /ned_version:/  { version = $2; gsub(/"/, "", version); split(version, v, "."); pkg = ned "-" v[1] "." v[2] }
        /^      - /     { print pkg " " $2 }
    ' "$TOPOLOGY_FILE"
}

first=true
while IFS=' ' read -r package netsim; do
    if [[ "$first" == true ]]; then
        echo "[INFO] Creating netsim network with package $package"
        mkdir -p "$NETSIM_DIR"
        ncs-netsim --dir "$NETSIM_DIR" create-network "$PACKAGES_DIR/$package" 1 dummy
        first=false
    fi

    echo "[INFO] Adding netsim device $netsim (package: $package)"
    (cd "$NETSIM_DIR" && ncs-netsim add-device "$PACKAGES_DIR/$package/" "$netsim")
done < <(parse_topology)

echo "[INFO] Starting netsim network"
(cd "$NETSIM_DIR" && ncs-netsim start)

echo "[INFO] Loading netsim config into NSO"
(cd "$NETSIM_DIR" && ncs-netsim ncs-xml-init > netsim_config.xml)
ncs_load -l -m "$NETSIM_DIR/netsim_config.xml"

echo "[INFO] Connecting and syncing devices"
echo "devices connect" | ncs_cli -Cu "$ADMIN_USERNAME"
echo "devices sync-from" | ncs_cli -Cu "$ADMIN_USERNAME"

echo "[OK] Netsim loading complete"