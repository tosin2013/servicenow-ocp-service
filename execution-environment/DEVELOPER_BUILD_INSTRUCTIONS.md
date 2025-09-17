# Developer Build Instructions for ServiceNow OCP Execution Environment

This document provides step-by-step instructions for developers to successfully build the ServiceNow OpenShift execution environment with all required Ansible collections.

## Prerequisites

1. **Ansible Builder** installed on your system
2. **Podman** or **Docker** container runtime
3. **Red Hat Automation Hub Token** (required for certified collections)
4. **Network access** to Red Hat registries and Automation Hub

## Quick Start (Recommended)

### Using the Makefile (Easiest Method)

```bash
# 1. Navigate to the execution environment directory
cd execution-environment/

# 2. Set your Red Hat Automation Hub token
export ANSIBLE_HUB_TOKEN="your_token_here"

# 3. Build using the Makefile
make build
```

## Manual Build Process

If you prefer to run `ansible-builder` directly, follow these steps:

### Step 1: Set Up Your Environment

```bash
# Navigate to the execution environment directory
cd execution-environment/

# Set your Red Hat Automation Hub token (required for redhat.sso and other certified collections)
export ANSIBLE_HUB_TOKEN="your_token_here"
```

### Step 2: Create Authentication Configuration

```bash
# Create ansible.cfg from template for Red Hat Automation Hub authentication
envsubst < files/ansible.cfg.template > ./ansible.cfg
```

### Step 3: Run Ansible Builder

```bash
# Build the execution environment
ansible-builder build \
    --tag quay.io/takinosh/servicenow-ocp-ee:latest \
    --verbosity 3 \
    --container-runtime podman
```

## Troubleshooting Common Issues

### Issue 1: "Cannot find redhat.sso.sso_user module"

**Problem**: The `redhat.sso` collection doesn't have a module called `sso_user`.

**Solution**: The correct modules in `redhat.sso:2.0.0` are:
- `redhat.sso.sso_client` - Manage SSO clients
- `redhat.sso.sso_role` - Manage SSO roles  
- `redhat.sso.sso_user_federation` - Manage user federation

Check available modules:
```bash
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc -l | grep redhat.sso
```

### Issue 2: "Authentication failed" or "Collection not found"

**Problem**: Missing or invalid Red Hat Automation Hub token.

**Solutions**:
1. Verify your token is valid: https://console.redhat.com/ansible/automation-hub/token
2. Ensure `ANSIBLE_HUB_TOKEN` environment variable is set
3. Check that `ansible.cfg` was created properly from the template

### Issue 3: "openshift-clients package not found"

**Problem**: The `kubernetes.core` collection requires OpenShift CLI tools.

**Solution**: This is already handled in our configuration:
- `bindep.txt` excludes the problematic package
- OpenShift CLI tools are installed via tarball in the container
- No action needed - the build should succeed

### Issue 4: Wrong directory or file paths

**Problem**: Running `ansible-builder` from the wrong directory.

**Solution**: 
- Always run from the `execution-environment/` directory
- Use the execution-environment.yml file in the current directory (not a subdirectory)

## Verifying Your Build

After a successful build, verify the collections are available:

```bash
# Test kubernetes.core collection
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc kubernetes.core.k8s

# Test redhat.sso collection
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc redhat.sso.sso_client

# Test community.general keycloak modules
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-doc community.general.keycloak_user

# List all available collections
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-galaxy collection list
```

## What's Included in This Execution Environment

### Collections
- `kubernetes.core:6.1.0` - Kubernetes and OpenShift automation
- `redhat.sso:2.0.0` - Red Hat SSO/Keycloak management
- `ansible.controller:4.6.19` - Ansible Automation Platform integration
- `ansible.hub:1.0.2` - Automation Hub integration
- `community.general:11.3.0` - General purpose modules
- `ansible.utils:6.0.0` - Utility modules

### CLI Tools
- `oc` and `kubectl` - OpenShift/Kubernetes CLI tools (installed via tarball)
- Standard RHEL 8 system packages

### Python Packages
- `kubernetes>=24.2.0` - Kubernetes Python client
- `requests-oauthlib` - OAuth authentication
- `jsonpatch` - JSON patch operations
- `ara` - ARA Records Ansible
- And other collection dependencies

## Directory Structure

```
execution-environment/
├── execution-environment.yml     # Main build configuration
├── files/
│   ├── requirements.yml          # Ansible collections
│   ├── requirements.txt          # Python packages
│   ├── bindep.txt                # System packages
│   └── ansible.cfg.template      # Authentication template
├── scripts/
│   └── assemble                  # Custom build script
├── Makefile                      # Build automation
└── DEVELOPER_BUILD_INSTRUCTIONS.md  # This file
```

## Getting Help

If you encounter issues:

1. Check the build logs: `ansible-builder.log`
2. Verify your Red Hat Automation Hub access
3. Ensure you're in the correct directory
4. Try using the Makefile instead of direct ansible-builder commands

## Additional Make Targets

```bash
make clean          # Clean build artifacts
make build          # Build the execution environment
make test           # Test the built image
make shell          # Get a shell in the container
make list           # List available images
```

## Notes

- The build process requires internet access to download collections and packages
- Red Hat certified collections require a valid subscription and Automation Hub token
- The build takes several minutes due to package installation and collection downloads
- The final image size is approximately 1.5GB