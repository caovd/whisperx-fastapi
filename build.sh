#!/usr/bin/env bash
# Build the WhisperX-FastAPI Docker image with MLIS integration patches.
#
# Usage:
#   ./build.sh <REGISTRY> [TAG]
#
# Example:
#   ./build.sh registry.example.com/whisperx-fastapi 0.5.1-mlis
#
set -euo pipefail

REGISTRY="${1:?Usage: $0 <REGISTRY> [TAG]}"
TAG="${2:-0.5.1-mlis}"
IMAGE="${REGISTRY}:${TAG}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR=$(mktemp -d)

trap 'rm -rf "${BUILD_DIR}"' EXIT

echo "==> Cloning upstream WhisperX-FastAPI..."
git clone --depth 1 https://github.com/pavelzbornik/whisperX-FastAPI.git "${BUILD_DIR}"

echo "==> Applying MLIS integration patch..."
cd "${BUILD_DIR}"
git apply "${SCRIPT_DIR}/patches/mlis-integration.patch"

echo "==> Building Docker image: ${IMAGE}"
docker build -t "${IMAGE}" .

echo "==> Pushing ${IMAGE}..."
docker push "${IMAGE}"

echo "==> Done. Image pushed: ${IMAGE}"
