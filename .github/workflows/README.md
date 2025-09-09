# Execution Environment CI/CD

This directory contains GitHub Actions workflows for building, testing, and deploying the ServiceNow-OpenShift custom execution environment.

## Workflows

### build-ee.yml
Automated CI/CD pipeline for the execution environment that:

1. **Builds** the container using ansible-builder
2. **Tests** Python dependencies, Ansible collections, and custom modules
3. **Scans** for security vulnerabilities using Trivy
4. **Generates** Software Bill of Materials (SBOM)
5. **Pushes** to container registry (Quay.io)
6. **Creates** releases for version tags

## Triggers

- **Push to main/develop**: Builds and pushes with `latest` or `dev-{sha}` tags
- **Release tags** (`ee-v*`): Creates versioned releases
- **Pull requests**: Runs tests without publishing

## Container Registry

Images are published to `quay.io/servicenow-ocp/servicenow-ocp-ee`

## Required Secrets

Configure these secrets in your GitHub repository:

- `REGISTRY_USERNAME`: Quay.io username
- `REGISTRY_PASSWORD`: Quay.io password/token

## Security

- Vulnerability scanning with Trivy
- SARIF results uploaded to GitHub Security tab
- SBOM generation for compliance
- Base image: Red Hat UBI8 (enterprise-grade)

## Versioning

- **Release tags**: `ee-v1.0.0` format
- **Main branch**: `latest` tag
- **Development**: `dev-{git-sha}` format

## Usage in AAP

```yaml
execution_environment:
  image: "quay.io/servicenow-ocp/servicenow-ocp-ee:latest"
```
