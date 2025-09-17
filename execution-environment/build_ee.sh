#!/bin/bash
# Build the custom execution environment

# Change to the script's directory to ensure correct context
cd "$(dirname "$0")"

# Variables
EE_IMAGE_NAME="quay.io/takinosh/servicenow-ocp-ee"
EE_IMAGE_TAG="latest"

# Download collections
echo "Downloading collections..."
ansible-galaxy collection download -r files/requirements.yml -p collections/

# Build the execution environment
echo "Building Execution Environment image: ${EE_IMAGE_NAME}:${EE_IMAGE_TAG}"
ansible-builder build \
  --tag "${EE_IMAGE_NAME}:${EE_IMAGE_TAG}" \
  --container-runtime podman \
  --verbosity 3 \
  -f execution-environment.yml

echo "Build complete. To push the image, run:"
echo "podman push ${EE_IMAGE_NAME}:${EE_IMAGE_TAG}"
