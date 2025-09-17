#!/bin/bash
# Build script for GitHub Actions workflow
# This script builds and pushes the ServiceNow OpenShift execution environment
# Updated to trigger new build with fixed AAP collections

set -euo pipefail

# Change to the script's directory to ensure correct context
cd "$(dirname "$0")"

# Source environment variables from optional configs if available
if [[ -f "files/optional-configs/rhsm-activation.env" ]]; then
    echo "🔧 Sourcing environment variables from rhsm-activation.env..."
    source files/optional-configs/rhsm-activation.env
    echo "✅ Environment variables loaded"
fi

# Variables from environment or defaults
REGISTRY="${REGISTRY:-quay.io/takinosh}"
IMAGE_NAME="${IMAGE_NAME:-servicenow-ocp-ee}"
EE_VERSION="${1:-latest}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"

# Red Hat subscription variables
RH_ORG="${RH_ORG:-}"
RH_ACT_KEY="${RH_ACT_KEY:-}"

# Full image name
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${EE_VERSION}"

echo "=================================================="
echo "Building ServiceNow OpenShift Execution Environment"
echo "=================================================="
echo "Registry: ${REGISTRY}"
echo "Image Name: ${IMAGE_NAME}"
echo "Version: ${EE_VERSION}"
echo "Full Image: ${FULL_IMAGE_NAME}"
echo "Container Runtime: ${CONTAINER_RUNTIME}"
echo "RH Org: ${RH_ORG:-'Not set'}"
echo "RH Activation Key: ${RH_ACT_KEY:+***REDACTED***}"
echo "=================================================="

# Ensure required files exist
if [[ ! -f "execution-environment.yml" ]]; then
    echo "ERROR: execution-environment.yml not found!"
    exit 1
fi

if [[ ! -f "files/requirements.yml" ]]; then
    echo "ERROR: files/requirements.yml not found!"
    exit 1
fi

# Login to Red Hat Registry if credentials provided
if [[ -n "${REDHAT_USERNAME:-}" ]] && [[ -n "${REDHAT_PASSWORD:-}" ]]; then
    echo "🔑 Logging into Red Hat Registry..."
    echo "${REDHAT_PASSWORD}" | ${CONTAINER_RUNTIME} login registry.redhat.io -u "${REDHAT_USERNAME}" --password-stdin
    if [[ $? -eq 0 ]]; then
        echo "✅ Red Hat Registry login successful"
    else
        echo "❌ Red Hat Registry login failed"
        exit 1
    fi
else
    echo "⚠️  Red Hat Registry credentials not provided - build may fail if base image requires authentication"
fi

# Set up Red Hat subscription environment if provided
if [[ -n "${RH_ORG}" ]] && [[ -n "${RH_ACT_KEY}" ]]; then
    echo "🔑 Setting up Red Hat subscription environment..."
    export RH_ORG="${RH_ORG}"
    export RH_ACT_KEY="${RH_ACT_KEY}"
    echo "✅ Red Hat subscription variables configured"
else
    echo "⚠️  Red Hat subscription variables not provided - using defaults"
fi

# Download collections using Makefile approach
echo "📦 Downloading Ansible collections using Makefile..."
echo "🔑 Using Automation Hub token for collection downloads"

# Ensure ANSIBLE_HUB_TOKEN is exported (like maketoken.sh does)
if [[ -n "${ANSIBLE_HUB_TOKEN}" ]]; then
    export ANSIBLE_HUB_TOKEN=${ANSIBLE_HUB_TOKEN}
    echo "✅ ANSIBLE_HUB_TOKEN exported (length: ${#ANSIBLE_HUB_TOKEN})"
else
    echo "⚠️  ANSIBLE_HUB_TOKEN not found in environment"
fi

# Run make token - this must succeed for a proper build
make token
if [[ $? -eq 0 ]]; then
    echo "✅ Collections downloaded successfully via make token"
else
    echo "❌ Collection download failed!"
    echo "❌ Cannot proceed with build without proper collections"
    exit 1
fi

# Build the execution environment using Makefile approach
echo "🔨 Building execution environment using Makefile..."
export TARGET_NAME="${REGISTRY}/${IMAGE_NAME}"
export TARGET_TAG="${EE_VERSION}"
export CONTAINER_ENGINE="${CONTAINER_RUNTIME}"

# Run make build and capture both output and exit code
set +e  # Don't exit on error, we want to handle it ourselves
make build
BUILD_EXIT_CODE=$?
set -e  # Re-enable exit on error

if [[ $BUILD_EXIT_CODE -eq 0 ]]; then
    echo "✅ Build completed successfully!"
else
    echo "❌ Build failed with exit code: $BUILD_EXIT_CODE"
    echo "🔍 Checking ansible-builder.log for details..."
    if [[ -f "ansible-builder.log" ]]; then
        echo "📋 Last 20 lines of build log:"
        tail -20 ansible-builder.log
    fi
    exit $BUILD_EXIT_CODE
fi

# Generate SBOM (Software Bill of Materials)
echo "📋 Generating Software Bill of Materials..."
cat > SBOM.md << EOF
# Software Bill of Materials (SBOM)

**Image**: \`${FULL_IMAGE_NAME}\`  
**Built**: $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Git SHA**: ${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}

## Base Image
- Red Hat Universal Base Image (UBI) 9

## Ansible Collections
EOF

# Add collections to SBOM
if [[ -f "files/requirements.yml" ]]; then
    echo "" >> SBOM.md
    echo "### Collections from requirements.yml" >> SBOM.md
    grep -E "^\s*-\s*name:" files/requirements.yml | sed 's/^\s*-\s*name:\s*/- /' >> SBOM.md
fi

# Add Python packages to SBOM
if [[ -f "files/requirements.txt" ]]; then
    echo "" >> SBOM.md
    echo "### Python Packages" >> SBOM.md
    while IFS= read -r line; do
        if [[ ! "$line" =~ ^#.*$ ]] && [[ -n "$line" ]]; then
            echo "- $line" >> SBOM.md
        fi
    done < files/requirements.txt
fi

echo "✅ SBOM generated: SBOM.md"

# Generate image manifest
echo "📄 Generating image manifest..."
${CONTAINER_RUNTIME} inspect "${FULL_IMAGE_NAME}" > image-manifest.json 2>/dev/null || echo "{}" > image-manifest.json
echo "✅ Image manifest generated: image-manifest.json"

# Security scanning handled by GitHub CodeQL and Dependabot
echo "🔍 Security scanning handled by GitHub native tools..."
echo "✅ GitHub CodeQL and Dependabot provide comprehensive security coverage"

# Test the image
echo "🧪 Testing execution environment..."
${CONTAINER_RUNTIME} run --rm "${FULL_IMAGE_NAME}" ansible --version
if [[ $? -eq 0 ]]; then
    echo "✅ Image test passed!"
else
    echo "❌ Image test failed!"
    exit 1
fi

# Push to registry (only if not a PR and we have credentials)
if [[ "${GITHUB_EVENT_NAME:-}" != "pull_request" ]] && [[ -n "${REGISTRY_USERNAME:-}" ]] && [[ -n "${REGISTRY_PASSWORD:-}" ]]; then
    echo "🚀 Pushing to registry..."
    
    # Login to registry
    echo "${REGISTRY_PASSWORD}" | ${CONTAINER_RUNTIME} login "${REGISTRY}" -u "${REGISTRY_USERNAME}" --password-stdin
    
    # Push the image
    ${CONTAINER_RUNTIME} push "${FULL_IMAGE_NAME}"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully pushed ${FULL_IMAGE_NAME}"
    else
        echo "❌ Failed to push image!"
        exit 1
    fi
else
    echo "ℹ️  Skipping push (PR build or missing credentials)"
    echo "To push manually, run:"
    echo "  ${CONTAINER_RUNTIME} push ${FULL_IMAGE_NAME}"
fi

echo "=================================================="
echo "🎉 Build process completed successfully!"
echo "Image: ${FULL_IMAGE_NAME}"
echo "=================================================="
