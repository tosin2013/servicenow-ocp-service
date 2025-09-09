#!/bin/bash
# Build script for ServiceNow OpenShift Custom Execution Environment

set -euo pipefail

# Configuration
EE_NAME="servicenow-ocp-ee"
EE_VERSION="${1:-latest}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
REGISTRY="${REGISTRY:-quay.io/your-org}"
BUILD_DIR="$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v ansible-builder &> /dev/null; then
        error "ansible-builder is not installed. Please install it with: pip install ansible-builder"
    fi
    
    if ! command -v ${CONTAINER_RUNTIME} &> /dev/null; then
        error "${CONTAINER_RUNTIME} is not installed or not in PATH"
    fi
    
    success "Prerequisites check passed"
}

# Validate execution environment definition
validate_ee_definition() {
    log "Validating execution environment definition..."
    
    if [[ ! -f "${BUILD_DIR}/execution-environment.yml" ]]; then
        error "execution-environment.yml not found in ${BUILD_DIR}"
    fi
    
    if [[ ! -f "${BUILD_DIR}/requirements.yml" ]]; then
        error "requirements.yml not found in ${BUILD_DIR}"
    fi
    
    if [[ ! -f "${BUILD_DIR}/requirements.txt" ]]; then
        error "requirements.txt not found in ${BUILD_DIR}"
    fi
    
    if [[ ! -f "${BUILD_DIR}/bindep.txt" ]]; then
        error "bindep.txt not found in ${BUILD_DIR}"
    fi
    
    success "Execution environment definition validation passed"
}

# Build the execution environment
build_execution_environment() {
    log "Building execution environment: ${EE_NAME}:${EE_VERSION}"
    
    cd "${BUILD_DIR}"
    
    # Build with ansible-builder
    ansible-builder build \
        --tag "${EE_NAME}:${EE_VERSION}" \
        --container-runtime "${CONTAINER_RUNTIME}" \
        --verbosity 2 \
        .
    
    if [[ $? -eq 0 ]]; then
        success "Execution environment built successfully: ${EE_NAME}:${EE_VERSION}"
    else
        error "Failed to build execution environment"
    fi
}

# Security scan the image
security_scan() {
    log "Running security scan on ${EE_NAME}:${EE_VERSION}"
    
    if command -v trivy &> /dev/null; then
        trivy image --exit-code 1 --severity HIGH,CRITICAL "${EE_NAME}:${EE_VERSION}"
        if [[ $? -eq 0 ]]; then
            success "Security scan passed"
        else
            error "Security scan failed - high or critical vulnerabilities found"
        fi
    else
        warn "Trivy not found - skipping security scan"
    fi
}

# Test the execution environment
test_execution_environment() {
    log "Testing execution environment..."
    
    # Test basic functionality
    log "Testing Python dependencies..."
    ${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" \
        python3 -c "import yaml, requests, kubernetes, openshift; print('Python dependencies OK')"
    
    # Test Ansible collections
    log "Testing Ansible collections..."
    ${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" \
        ansible-galaxy collection list
    
    # Test OpenShift CLI
    log "Testing OpenShift CLI..."
    ${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" \
        oc version --client
    
    # Test custom modules
    log "Testing custom modules..."
    ${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" \
        python3 -c "import sys; sys.path.append('/opt/ansible/custom-modules'); import servicenow_connection_alias; print('Custom modules OK')"
    
    success "Execution environment testing completed successfully"
}

# Tag and push to registry
push_to_registry() {
    if [[ -z "${REGISTRY}" ]]; then
        warn "No registry specified - skipping push"
        return
    fi
    
    log "Tagging and pushing to registry: ${REGISTRY}/${EE_NAME}:${EE_VERSION}"
    
    # Tag for registry
    ${CONTAINER_RUNTIME} tag "${EE_NAME}:${EE_VERSION}" "${REGISTRY}/${EE_NAME}:${EE_VERSION}"
    
    # Also tag as latest if this is a release version
    if [[ "${EE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ${CONTAINER_RUNTIME} tag "${EE_NAME}:${EE_VERSION}" "${REGISTRY}/${EE_NAME}:latest"
        log "Also tagged as latest"
    fi
    
    # Push to registry
    ${CONTAINER_RUNTIME} push "${REGISTRY}/${EE_NAME}:${EE_VERSION}"
    
    if [[ "${EE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ${CONTAINER_RUNTIME} push "${REGISTRY}/${EE_NAME}:latest"
    fi
    
    success "Successfully pushed to registry"
}

# Generate image manifest
generate_manifest() {
    log "Generating image manifest..."
    
    cat > "${BUILD_DIR}/image-manifest.json" << EOF
{
  "image": "${REGISTRY}/${EE_NAME}:${EE_VERSION}",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "${EE_VERSION}",
  "base_image": "registry.redhat.io/ubi8/ubi:latest",
  "ansible_collections": [
    $(${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" ansible-galaxy collection list --format json | jq -c '.')
  ],
  "python_packages": [
    $(${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" pip list --format json | jq -c '.')
  ],
  "system_packages": [
    $(${CONTAINER_RUNTIME} run --rm "${EE_NAME}:${EE_VERSION}" rpm -qa --qf '"%{NAME}-%{VERSION}-%{RELEASE}",' | sed 's/,$//')
  ]
}
EOF
    
    success "Image manifest generated: ${BUILD_DIR}/image-manifest.json"
}

# Main execution
main() {
    log "Starting execution environment build process..."
    log "Version: ${EE_VERSION}"
    log "Container Runtime: ${CONTAINER_RUNTIME}"
    log "Registry: ${REGISTRY:-none}"
    
    check_prerequisites
    validate_ee_definition
    build_execution_environment
    security_scan
    test_execution_environment
    
    if [[ -n "${REGISTRY}" ]]; then
        push_to_registry
    fi
    
    generate_manifest
    
    success "Execution environment build process completed successfully!"
    log "Image: ${EE_NAME}:${EE_VERSION}"
    if [[ -n "${REGISTRY}" ]]; then
        log "Registry: ${REGISTRY}/${EE_NAME}:${EE_VERSION}"
    fi
}

# Show usage information
usage() {
    echo "Usage: $0 [VERSION]"
    echo ""
    echo "Build ServiceNow OpenShift Custom Execution Environment"
    echo ""
    echo "Arguments:"
    echo "  VERSION    Image version tag (default: latest)"
    echo ""
    echo "Environment Variables:"
    echo "  CONTAINER_RUNTIME    Container runtime to use (default: podman)"
    echo "  REGISTRY            Container registry for pushing (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build with 'latest' tag"
    echo "  $0 1.0.0             # Build with specific version"
    echo "  REGISTRY=quay.io/myorg $0 1.0.0  # Build and push to registry"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
