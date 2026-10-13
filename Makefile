SHELL := /bin/bash

.PHONY: help build push build-push compile preconfig-reload topology wait-ready init claude-code

help:
	@echo "Available targets:"
	@echo "  make build       Build Docker image"
	@echo "  make push        Push Docker image"
	@echo "  make build-push  Build and push Docker image"
	@echo "  make compile     Compile service packages"
	@echo "  make preconfig-reload  Reload preconfiguration files"
	@echo "  make topology    Load network simulators"
	@echo "  make wait-ready  Wait for NSO readiness"
	@echo "  make init        Initialize development environment (compile, preconfig-reload, topology)"
	@echo "  make claude-code Install the Claude Code CLI in the dev container"

build:
	@bash scripts/build-image.sh

push:
	@bash scripts/push-image.sh

compile:
	@bash scripts/compile-packages.sh

preconfig-reload:
	@bash scripts/nso-load.sh

topology:
	@bash scripts/load-netsims.sh

wait-ready:
	@bash scripts/devcontainer-init.sh

claude-code:
	@bash scripts/install-claude-code.sh

build-push: build push

init: compile preconfig-reload topology