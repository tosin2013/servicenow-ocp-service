---
title: Execution Environment Reference
---

# Execution Environment Reference

**Technical reference for the ServiceNow-OpenShift integration execution environment components, collections, and configuration**

## 📋 Container Image Details

### Current Image
- **Registry**: `quay.io/takinosh/servicenow-ocp-ee`
- **Latest Tag**: `quay.io/takinosh/servicenow-ocp-ee:latest`
- **Base Image**: `registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest`
- **Architecture**: `linux/amd64`
- **Size**: ~1.5GB

### Image Layers
```dockerfile
# Base: RHEL 9 UBI with Ansible Core
FROM registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest

# System packages via bindep
RUN microdnf install -y git curl jq

# Python packages via pip
RUN pip3 install --no-cache-dir -r requirements.txt

# Ansible collections via galaxy
RUN ansible-galaxy collection install -r requirements.yml

# Custom configurations
COPY ansible.cfg /etc/ansible/ansible.cfg
```

## 📦 Installed Collections

### Core Collections
| Collection | Version | Purpose |
|------------|---------|---------|
| `kubernetes.core` | 6.1.0 | Kubernetes/OpenShift automation |
| `servicenow.itsm` | 2.6.0 | ServiceNow ITSM integration |
| `redhat.sso` | 2.0.0 | Red Hat SSO/Keycloak management |
| `ansible.controller` | 4.6.19 | Ansible Automation Platform |
| `community.general` | 11.3.0 | General purpose modules |
| `ansible.utils` | 6.0.0 | Utility modules and filters |
| `ansible.hub` | 1.0.2 | Automation Hub integration |

### Collection Details

#### kubernetes.core
```yaml
# Key modules:
- k8s                    # Manage Kubernetes resources
- k8s_info              # Gather Kubernetes resource info
- k8s_exec              # Execute commands in pods
- k8s_cp                # Copy files to/from pods
- k8s_drain             # Drain nodes
- k8s_scale             # Scale deployments
```

#### servicenow.itsm
```yaml
# Key modules:
- incident              # Manage incidents
- service_catalog       # Service catalog operations
- catalog_request       # Catalog request management
- configuration_item    # CMDB operations
- change_request        # Change management
- problem               # Problem management
```

#### redhat.sso
```yaml
# Key modules:
- sso_client           # Manage SSO clients
- sso_realm            # Manage SSO realms
- sso_user             # Manage SSO users
- sso_group            # Manage SSO groups
- sso_role             # Manage SSO roles
```

## 🐍 Python Packages

### Core Python Dependencies
```txt
# HTTP and API clients
requests==2.31.0
urllib3==2.0.7

# JSON and data processing
jinja2==3.1.2
pyyaml==6.0.1

# Kubernetes client
kubernetes==28.1.0
openshift==0.13.2

# ServiceNow client libraries
pysnow==0.7.17

# Utility libraries
netaddr==0.10.1
dnspython==2.4.2
```

### Python Environment
- **Python Version**: 3.9+
- **Package Manager**: pip
- **Virtual Environment**: Container-isolated
- **Site Packages**: `/usr/local/lib/python3.9/site-packages/`

## 🛠️ System Tools

### CLI Tools Available
| Tool | Version | Purpose |
|------|---------|---------|
| `oc` | 4.19+ | OpenShift CLI |
| `kubectl` | 1.29+ | Kubernetes CLI |
| `curl` | Latest | HTTP client |
| `jq` | Latest | JSON processor |
| `git` | Latest | Version control |
| `ssh` | Latest | Secure shell |

### Tool Locations
```bash
/usr/local/bin/oc          # OpenShift CLI
/usr/bin/kubectl           # Kubernetes CLI (symlink to oc)
/usr/bin/curl              # HTTP client
/usr/bin/jq                # JSON processor
/usr/bin/git               # Git client
/usr/bin/ssh               # SSH client
```

## ⚙️ Configuration Files

### Ansible Configuration
**Location**: `/etc/ansible/ansible.cfg`

```ini
[defaults]
host_key_checking = False
gathering = smart
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### Collection Paths
```bash
# System collections
/usr/share/ansible/collections/

# User collections (if any)
~/.ansible/collections/

# Collections search path
ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
```

## 🔐 Security Configuration

### User Context
- **User**: `ansible` (UID: 1000)
- **Group**: `ansible` (GID: 1000)
- **Home**: `/home/ansible`
- **Shell**: `/bin/bash`

### File Permissions
```bash
# Ansible configuration
/etc/ansible/ansible.cfg     # 644 (readable by all)

# Collections directory
/usr/share/ansible/collections/  # 755 (executable by all)

# Python packages
/usr/local/lib/python3.9/site-packages/  # 755
```

### Security Features
- **Non-root execution** - Runs as ansible user
- **Minimal base image** - RHEL UBI with minimal packages
- **No SSH keys** - Uses external authentication
- **Read-only filesystem** - Immutable container design

## 🌐 Network Configuration

### Default Ports
- **No exposed ports** - Execution environment doesn't run services
- **Outbound connections** - HTTPS (443), HTTP (80), SSH (22)

### DNS Configuration
- **Resolver**: System default
- **Search domains**: Inherited from host
- **Custom DNS**: Configurable via container runtime

## 📁 Directory Structure

### Important Paths
```bash
/etc/ansible/                    # Ansible configuration
├── ansible.cfg                  # Main configuration
└── collections/                 # Collection overrides (if any)

/usr/share/ansible/              # Ansible installation
├── collections/                 # Installed collections
└── plugins/                     # Ansible plugins

/home/ansible/                   # User home directory
├── .ansible/                    # User Ansible config
└── .ssh/                        # SSH configuration (if needed)

/tmp/                           # Temporary files
└── ansible-*                   # Ansible temporary files
```

### Volume Mount Points
```bash
# Common mount points when running
/workspace                      # Project files
/runner                        # AAP runner directory
/tmp                           # Temporary files
```

## 🔧 Build Configuration

### Build Files
```bash
execution-environment/
├── execution-environment.yml   # Main EE definition
├── files/
│   ├── requirements.yml       # Ansible collections
│   ├── requirements.txt       # Python packages
│   ├── bindep.txt            # System packages
│   └── ansible.cfg           # Ansible configuration
└── Makefile                   # Build automation
```

### Build Process
1. **Base Image** - Pull RHEL 9 UBI with Ansible
2. **System Packages** - Install via microdnf (bindep.txt)
3. **Python Packages** - Install via pip (requirements.txt)
4. **Ansible Collections** - Install via galaxy (requirements.yml)
5. **Configuration** - Copy custom configs
6. **Cleanup** - Remove build artifacts

### Build Variables
```bash
# Environment variables used during build
ANSIBLE_HUB_TOKEN              # Red Hat Automation Hub token
CONTAINER_ENGINE=podman        # Container runtime
EE_IMAGE_NAME                  # Target image name
EE_IMAGE_TAG                   # Target image tag
```

## 🚀 Runtime Configuration

### Environment Variables
```bash
# Ansible runtime variables
ANSIBLE_HOST_KEY_CHECKING=False
ANSIBLE_GATHERING=smart
ANSIBLE_RETRY_FILES_ENABLED=False
PYTHONUNBUFFERED=1

# Custom paths
ANSIBLE_LIBRARY=/opt/ansible/custom-modules
ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections
```

### Resource Requirements
```yaml
# Minimum requirements
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

## 📊 Monitoring and Logging

### Log Locations
```bash
# Ansible logs (when configured)
/tmp/ansible.log               # Main log file

# Collection logs
/tmp/ansible-collections.log   # Collection-specific logs

# System logs
/var/log/                     # System logs (if accessible)
```

### Metrics
- **Image size**: ~1.5GB
- **Startup time**: ~5-10 seconds
- **Memory usage**: 200-500MB baseline
- **CPU usage**: Varies by workload

## 🔄 Version Management

### Tagging Strategy
```bash
# Production tags
quay.io/takinosh/servicenow-ocp-ee:latest
quay.io/takinosh/servicenow-ocp-ee:v1.0.0
quay.io/takinosh/servicenow-ocp-ee:stable

# Development tags
quay.io/takinosh/servicenow-ocp-ee:dev
quay.io/takinosh/servicenow-ocp-ee:feature-branch
quay.io/takinosh/servicenow-ocp-ee:commit-hash
```

### Update Process
1. **Modify** configuration files
2. **Build** new image locally
3. **Test** with validation playbooks
4. **Tag** with appropriate version
5. **Push** to registry
6. **Update** AAP job templates

## 🔗 Integration Points

### Ansible Automation Platform
- **Job Templates** - Use EE as execution environment
- **Credentials** - Injected at runtime
- **Projects** - Mounted as volumes

### OpenShift Integration
- **Service Account** - Uses cluster credentials
- **RBAC** - Permissions via service account
- **Network Policies** - Controlled access

### ServiceNow Integration
- **API Credentials** - From Ansible vault
- **OAuth Tokens** - Managed externally
- **Business Rules** - Trigger EE execution

---
*This reference provides complete technical details for the ServiceNow-OpenShift integration execution environment*
