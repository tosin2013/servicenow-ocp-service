# ServiceNow-OpenShift Custom Execution Environment

Enterprise-grade execution environment for Ansible Automation Platform (AAP) that provides specialized automation capabilities for ServiceNow and OpenShift integration.

## Overview

This custom execution environment (EE) is designed to support the four-tier ServiceNow-OpenShift integration architecture as defined in ADR-010 and ADR-011. It includes all necessary dependencies, tools, and custom modules for enterprise automation workflows.

## Key Features

- **Enterprise Base**: Red Hat UBI8 for security and support
- **ServiceNow Integration**: Custom modules for connection management
- **OpenShift Native**: Full OpenShift CLI and Kubernetes API support
- **Security Hardened**: Vulnerability scanning and compliance
- **CI/CD Ready**: Automated building and registry publishing

## Components

### Python Libraries
- `python-keycloak`: Identity and access management
- `openshift`: OpenShift cluster interaction
- `kubernetes`: Kubernetes API operations
- `requests`: HTTP API interactions
- `PyYAML`: Configuration management

### Ansible Collections
- `kubernetes.core`: Kubernetes resource management
- `redhat.openshift`: OpenShift-specific operations
- `servicenow.itsm`: ServiceNow automation
- `community.general`: General utilities

### Custom Modules
- `servicenow_connection_alias`: ServiceNow credential management
- `openshift_project_with_rbac`: OpenShift project automation

### System Tools
- OpenShift CLI (`oc`)
- Kubernetes CLI (`kubectl`)
- Git for GitOps workflows

## Building

### Local Build
```bash
cd execution-environment
./build.sh
```

### CI/CD Build
Automatic builds triggered by:
- Push to `main` or `develop` branches
- Release tags (`ee-v*`)
- Pull requests (test only)

## Usage

### In Ansible Automation Platform
```yaml
# job_template.yml
execution_environment:
  image: "quay.io/servicenow-ocp/servicenow-ocp-ee:latest"
  pull: "always"
```

### In Ansible Playbooks
```yaml
# playbook.yml
- name: Use custom modules
  servicenow_connection_alias:
    instance: "{{ servicenow_instance }}"
    credential_alias: "openshift-integration"
    connection_type: "oauth2"
    # ... other parameters
```

## Security

### Vulnerability Scanning
- Automated Trivy scanning in CI/CD
- SARIF results in GitHub Security tab
- Regular base image updates

### Compliance
- Software Bill of Materials (SBOM) generation
- Red Hat UBI8 certified base image
- No unnecessary packages or tools

### Access Control
- Registry authentication required
- Version-pinned dependencies
- Immutable container layers

## Testing

### Automated Tests
- Python import validation
- Ansible collection verification
- Custom module loading tests
- CLI tool availability checks

### Manual Testing
```bash
# Test container locally
podman run -it quay.io/servicenow-ocp/servicenow-ocp-ee:latest bash

# Verify Python libraries
python3 -c "import openshift, kubernetes, requests; print('OK')"

# Check Ansible collections
ansible-galaxy collection list

# Test OpenShift CLI
oc version --client
```

## Versioning

### Release Process
1. Create release branch: `release/ee-v1.0.0`
2. Update version in documentation
3. Create tag: `git tag ee-v1.0.0`
4. Push tag: `git push origin ee-v1.0.0`
5. GitHub Actions creates release automatically

### Version Format
- **Semantic versioning**: `ee-v1.0.0`
- **Development builds**: `dev-{git-sha}`
- **Latest stable**: `latest` tag

## Registry

### Container Images
- **Registry**: `quay.io/servicenow-ocp`
- **Repository**: `servicenow-ocp-ee`
- **Tags**: Version tags and `latest`

### Pull Images
```bash
podman pull quay.io/servicenow-ocp/servicenow-ocp-ee:latest
```

## Troubleshooting

### Build Issues
- Verify ansible-builder version >= 3.0.0
- Check base image availability
- Validate requirements files syntax

### Runtime Issues
- Check container logs: `podman logs <container-id>`
- Verify environment variables
- Test network connectivity to APIs

### Security Scan Failures
- Review Trivy scan results
- Update base image for CVE fixes
- Pin vulnerable package versions

## Development

### Adding Dependencies
1. Update `requirements.txt` for Python packages
2. Update `requirements.yml` for Ansible collections
3. Update `bindep.txt` for system packages
4. Test build locally before committing

### Custom Modules
1. Add new modules to `custom-modules/`
2. Follow Ansible module development guidelines
3. Include comprehensive documentation
4. Add unit tests where possible

## Support

### Documentation
- ADR-011: Custom Execution Environment specification
- ADR-010: Ansible Automation Platform integration
- GitHub Actions workflow documentation

### Issues
- GitHub Issues for bug reports
- Security issues via private disclosure
- Feature requests through enhancement proposals

## License

Enterprise deployment - contact your Red Hat representative for licensing information.
