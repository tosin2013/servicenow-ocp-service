# ServiceNow-OpenShift Execution Environment CI/CD

This directory contains GitHub Actions workflows for building, testing, and deploying the ServiceNow-OpenShift custom execution environment with comprehensive AAP integration capabilities.

## 🚀 Workflows

### build-ee.yml
**Automated CI/CD pipeline** for the execution environment that:

1. **🔨 Builds** the container using ansible-builder with AAP collections
2. **🧪 Tests** Python dependencies, Ansible collections, and custom modules
3. **🔍 Scans** for security vulnerabilities using Trivy
4. **📋 Generates** Software Bill of Materials (SBOM) for compliance
5. **🚀 Pushes** to container registry (Quay.io)
6. **📦 Creates** GitHub releases for version tags
7. **🔐 Security** scanning with SARIF upload to GitHub Security tab

## 🎯 Pipeline Triggers

| Trigger | Action | Image Tag | Registry Push |
|---------|--------|-----------|---------------|
| **Push to `main`** | Build + Test + Push | `latest` | ✅ Yes |
| **Push to `develop`** | Build + Test + Push | `dev-{sha}` | ✅ Yes |
| **Release tags** (`ee-v*`) | Build + Test + Push + Release | `{version}` | ✅ Yes |
| **Pull Requests** | Build + Test Only | `pr-{number}` | ❌ No |
| **Manual Dispatch** | Build + Test + Push | `manual-{sha}` | ✅ Yes |

## 🏗️ Pipeline Environment Variables

### **Built-in Environment Variables**
These are automatically set by the workflow:

```yaml
env:
  REGISTRY: quay.io/takinosh           # Container registry URL
  IMAGE_NAME: servicenow-ocp-ee       # Base image name
  CONTAINER_RUNTIME: podman           # Container runtime (podman/docker)
```

### **Dynamic Variables** (Generated during build)
```bash
EE_VERSION="${1:-latest}"            # Version tag from git ref or parameter
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${EE_VERSION}"
GITHUB_SHA="${GITHUB_SHA}"           # Git commit SHA
GITHUB_REF="${GITHUB_REF}"           # Git reference (branch/tag)
GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME}" # Event type (push/pull_request/etc)
```

## 🔐 Required Repository Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### **Container Registry Authentication**
| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `REGISTRY_USERNAME` | Quay.io username | `takinosh` | ✅ Yes |
| `REGISTRY_PASSWORD` | Quay.io password/robot token | `your-quay-token` | ✅ Yes |

### **Red Hat Subscription Management**
| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `RH_ORG` | Red Hat Organization ID | `1234567` | ✅ Yes |
| `RH_ACT_KEY` | Red Hat Activation Key | `your-activation-key-uuid` | ✅ Yes |

### **Optional Secrets** (for enhanced features)
| Secret Name | Description | Required |
|-------------|-------------|----------|
| `ANSIBLE_HUB_TOKEN` | Red Hat Automation Hub token | Recommended |
| `SLACK_WEBHOOK_URL` | Slack notifications | Optional |
| `TEAMS_WEBHOOK_URL` | Microsoft Teams notifications | Optional |

### **🔧 How to Configure Secrets**

#### **1. Red Hat Subscription Setup**
```bash
# Get your Red Hat Organization ID
# Visit: https://access.redhat.com/management/organization
# Your Org ID: 1234567 (example)

# Create an Activation Key
# Visit: https://access.redhat.com/management/activation_keys
# Create key with appropriate subscriptions
# Your Activation Key: your-activation-key-uuid (example)
```

#### **2. Quay.io Registry Setup**
```bash
# Create robot account at: https://quay.io/organization/takinosh?tab=robots
# Or use your personal credentials
# Username: takinosh
# Password/Token: your-quay-token
```

#### **3. Add Secrets to GitHub**
1. Go to your repository: `https://github.com/tosin2013/servicenow-ocp-service`
2. Navigate to: `Settings > Secrets and variables > Actions`
3. Click `New repository secret`
4. Add each secret with the exact names listed above

#### **4. Verify Secret Configuration**
The pipeline will show masked values in logs:
```
RH Org: 1234567
RH Activation Key: ***REDACTED***
Registry: quay.io/takinosh
```

## 🛡️ Security & Compliance

### **Security Scanning**
- **Trivy**: Comprehensive vulnerability scanning
- **SARIF Upload**: Results uploaded to GitHub Security tab
- **CVE Database**: Updated vulnerability database
- **Base Image**: Red Hat Universal Base Image 9 (enterprise-grade)

### **Compliance Features**
- **SBOM Generation**: Software Bill of Materials for audit trails
- **Image Manifest**: Complete container metadata
- **Build Provenance**: Full build history and dependencies
- **Security Policies**: Automated security policy enforcement

## 📋 Build Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| `SBOM.md` | `execution-environment/` | Software Bill of Materials |
| `image-manifest.json` | `execution-environment/` | Container image metadata |
| `trivy-results.sarif` | Repository root | Security scan results |
| `build-outputs/` | `execution-environment/` | Ansible-builder outputs |

## 🏷️ Image Versioning Strategy

| Git Reference | Image Tag | Example | Usage |
|---------------|-----------|---------|-------|
| `main` branch | `latest` | `quay.io/takinosh/servicenow-ocp-ee:latest` | Production |
| `develop` branch | `dev-{sha}` | `quay.io/takinosh/servicenow-ocp-ee:dev-a1b2c3d` | Development |
| Release tag `ee-v1.2.3` | `1.2.3` | `quay.io/takinosh/servicenow-ocp-ee:1.2.3` | Versioned Release |
| Pull Request #42 | `pr-42` | `quay.io/takinosh/servicenow-ocp-ee:pr-42` | Testing Only |

## 🔧 Pipeline Configuration

### **Execution Environment Components**
The pipeline builds an execution environment containing:

#### **Ansible Collections** (from `execution-environment/files/requirements.yml`)
```yaml
collections:
  - name: redhat_cop.aap_utilities     # AAP utility functions
  - name: ansible.platform            # AAP platform management
  - name: ansible.controller          # AAP controller API
  - name: ansible.hub                 # Automation Hub integration
  - name: kubernetes.core             # OpenShift/K8s operations
  - name: community.general           # General utilities
  - name: redhat.sso                  # Keycloak/RH-SSO integration
```

#### **Python Dependencies** (from `execution-environment/files/requirements.txt`)
```txt
python-keycloak>=3.7.0              # Keycloak API client
openshift>=0.13.1                   # OpenShift Python client
kubernetes>=24.2.0                  # Kubernetes Python client
requests>=2.28.0                    # HTTP client library
PyYAML>=6.0                         # YAML processing
jinja2>=3.1.0                       # Template engine
```

#### **System Packages** (from `execution-environment/files/bindep.txt`)
```txt
openshift-clients [platform:rhel-9] # OpenShift CLI tools
git [platform:rhel-9]               # Git client
curl [platform:rhel-9]              # HTTP client
```

## 🚀 Usage in Ansible Automation Platform

### **Job Template Configuration**
```yaml
# In AAP Job Template
execution_environment:
  image: "quay.io/takinosh/servicenow-ocp-ee:latest"
  pull: "always"  # Ensure latest image is used
```

### **Ansible Navigator Configuration**
```yaml
# ansible-navigator.yml
ansible-navigator:
  execution-environment:
    image: quay.io/takinosh/servicenow-ocp-ee:latest
    pull:
      policy: always
    container-engine: podman
```

### **Local Development Usage**
```bash
# Run playbook with custom EE
ansible-navigator run playbook.yml \
  --execution-environment-image quay.io/takinosh/servicenow-ocp-ee:latest \
  --mode stdout

# Interactive mode
ansible-navigator \
  --execution-environment-image quay.io/takinosh/servicenow-ocp-ee:latest
```

## 🔄 Manual Pipeline Triggers

### **Trigger Build via GitHub CLI**
```bash
# Trigger workflow manually
gh workflow run build-ee.yml

# Trigger with specific branch
gh workflow run build-ee.yml --ref develop
```

### **Create Release Tag**
```bash
# Create and push release tag
git tag ee-v1.2.3
git push origin ee-v1.2.3

# This will trigger:
# 1. Build with version 1.2.3
# 2. Push to quay.io/takinosh/servicenow-ocp-ee:1.2.3
# 3. Create GitHub release with artifacts
```

## 🐛 Troubleshooting

### **Common Pipeline Issues**

#### **Build Failures**
| Error | Cause | Solution |
|-------|-------|----------|
| `ansible-builder: command not found` | Missing ansible-builder | Check Python setup step |
| `Collection download failed` | Network/auth issues | Verify ANSIBLE_HUB_TOKEN |
| `Podman build failed` | Container runtime issues | Check Podman installation |
| `Push denied` | Registry auth failure | Verify REGISTRY_* secrets |

#### **Collection Issues**
```bash
# Debug collection downloads locally
cd execution-environment
ansible-galaxy collection download -r files/requirements.yml -p collections/ --force -vvv
```

#### **Image Testing**
```bash
# Test built image locally
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible --version
podman run --rm quay.io/takinosh/servicenow-ocp-ee:latest ansible-galaxy collection list
```

### **Pipeline Monitoring**
- **GitHub Actions**: Monitor builds at `https://github.com/tosin2013/servicenow-ocp-service/actions`
- **Security Alerts**: Check `Security > Code scanning alerts`
- **Registry**: Monitor images at `https://quay.io/repository/takinosh/servicenow-ocp-ee`

## 📞 Support & Maintenance

### **Regular Maintenance Tasks**
1. **Monthly**: Update base image and dependencies
2. **Quarterly**: Review and update Ansible collections
3. **As Needed**: Security patches and vulnerability fixes
4. **Before Releases**: Full integration testing

### **Monitoring Checklist**
- [ ] Pipeline success rate > 95%
- [ ] Security scan results reviewed
- [ ] Image size optimization
- [ ] Collection version compatibility
- [ ] AAP integration testing

---

**📚 Additional Resources:**
- [Ansible Builder Documentation](https://ansible-builder.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Quay.io Documentation](https://docs.quay.io/)
- [ServiceNow-OpenShift Integration Guide](../INTEGRATION_TESTING_GUIDE.md)
