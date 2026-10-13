#!/bin/bash
# install-artifacts.sh
#
# Called during "docker build" to install NSO NED packages into the image.
#
# It reads every artifact URL from nso-lab-topology.yaml, downloads each one,
# and unpacks it into /opt/ncs/packages so NSO can load it at startup.
#
# Two artifact formats are supported:
#   *.tar.gz      — plain tarball, unpacked directly.
#   *.signed.bin  — Cisco self-extracting signed bundle. It must be executed
#                   first (this produces a plain .tar.gz), which is then unpacked.

set -euo pipefail

ARTIFACTS_FILE="/tmp/artifacts.yaml"
DOWNLOAD_DIR="/tmp/ned-downloads"
INSTALL_DIR="/opt/ncs/packages"

mkdir -p "$DOWNLOAD_DIR"

# Parse artifact URLs:
# Reads every list entry under "urls:" from artifacts.yaml and extracts
# the URL value. No external YAML parser is required.
echo "[🔍] Reading artifact URLs from $ARTIFACTS_FILE ..."
urls=$(grep '^\s*-\s*http' "$ARTIFACTS_FILE" | awk '{print $2}')

# Download and install each artifact
for url in $urls; do

    filename=$(basename "$url")
    echo ""
    echo "[⬇️] Downloading: $filename"
    curl -fsSL --retry 3 -o "$DOWNLOAD_DIR/$filename" "$url"

    if [[ "$filename" == *.signed.bin ]]; then

        # Cisco signed bundles are self-extracting executables.
        # Running with --skip-verification extracts the inner .tar.gz
        # into the same directory without checking Cisco's signature.
        echo "[📦] Running signed bundle to extract inner tarball ..."
        chmod +x "$DOWNLOAD_DIR/$filename"
        ( cd "$DOWNLOAD_DIR" && ./"$filename" --skip-verification )

        # The extracted tarball has the same base name but with .tar.gz extension
        tarball="${filename%.signed.bin}.tar.gz"
        echo "[📦] Unpacking $tarball into $INSTALL_DIR ..."
        tar -xf "$DOWNLOAD_DIR/$tarball" -C "$INSTALL_DIR"

    else
        # Plain tarball: unpack directly
        echo "[📦] Unpacking $filename into $INSTALL_DIR ..."
        tar -xf "$DOWNLOAD_DIR/$filename" -C "$INSTALL_DIR"

    fi

    echo "[✔] $filename installed successfully."
done

# Cleanup:
# Remove downloaded files so they don't bloat the final image layer.
rm -rf "$DOWNLOAD_DIR"

echo ""
echo "[✅] All artifacts installed into $INSTALL_DIR"
