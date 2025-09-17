# Security Policy

## Supported Versions

We actively support the following versions of the ServiceNow OpenShift Service:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| develop | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

### For Critical Security Issues

1. **DO NOT** create a public GitHub issue
2. Email the maintainer directly at: tosin.akinosho@gmail.com
3. Include detailed information about the vulnerability
4. Allow up to 48 hours for initial response

### For Non-Critical Security Issues

1. Create a private security advisory on GitHub
2. Go to the Security tab → Advisories → New draft security advisory
3. Provide detailed information about the issue

## Security Features Enabled

This repository uses the following GitHub security features:

- **Dependabot**: Automatically creates pull requests for dependency updates
- **CodeQL Analysis**: Scans code for security vulnerabilities
- **Secret Scanning**: Detects accidentally committed secrets
- **Dependency Review**: Reviews dependencies in pull requests

## Security Best Practices

### Credentials Management

- All sensitive credentials are stored in GitHub Secrets
- Vault passwords are encrypted using Ansible Vault
- Service account tokens are rotated regularly
- No hardcoded credentials in source code

### Container Security

- Base images are scanned for vulnerabilities
- Execution environment uses Red Hat UBI (Universal Base Image)
- Regular updates to base images and dependencies
- Minimal attack surface with only required packages

### Infrastructure Security

- OpenShift RBAC controls access to resources
- ServiceNow integration uses OAuth 2.0
- Network policies restrict pod-to-pod communication
- Secrets are mounted as volumes, not environment variables

## Vulnerability Response

When a vulnerability is reported:

1. **Acknowledgment**: Within 48 hours
2. **Assessment**: Within 1 week
3. **Fix Development**: Timeline depends on severity
4. **Release**: Security fixes are prioritized
5. **Disclosure**: After fix is available

## Security Updates

Security updates are released as:

- **Critical**: Immediate patch release
- **High**: Within 1 week
- **Medium**: Next scheduled release
- **Low**: Next major release

## Contact

For security-related questions or concerns:

- **Email**: tosin.akinosho@gmail.com
- **GitHub**: @tosin2013
- **Security Advisories**: Use GitHub's private advisory feature
