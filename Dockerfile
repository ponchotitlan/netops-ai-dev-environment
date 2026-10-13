# ─────────────────────────────────────────────────────────────────────────────
# NSO custom development image
# Base image is specified in .env as NSO_BASE
# Layers added:
#   1. Python libraries from requirements.txt
#   2. NED artifacts declared in nso-lab-topology.yaml
# ─────────────────────────────────────────────────────────────────────────────

ARG NSO_BASE
FROM ${NSO_BASE}

# Ensure we are running as root
USER root

# Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# NED artifacts
COPY artifacts.yaml /tmp/artifacts.yaml
COPY scripts/install-artifacts.sh /tmp/install-artifacts.sh
RUN chmod +x /tmp/install-artifacts.sh \
    && /tmp/install-artifacts.sh \
    && rm -f /tmp/artifacts.yaml /tmp/install-artifacts.sh
