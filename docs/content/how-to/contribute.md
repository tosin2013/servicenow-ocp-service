# Contributing to Documentation

Thank you for your interest in contributing to the ServiceNow-OpenShift integration documentation!

## Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally using `cd docs && ./run-docs.sh`
5. Submit a pull request

## Documentation Standards

- Follow the [Diátaxis framework](https://diataxis.fr/)
- Use clear, concise language
- Include code examples where appropriate
- Test all links before submitting

## Local Development

### Prerequisites
- Podman or Docker
- Git

### Running Locally
```bash
cd docs
./run-docs.sh start
```

This will:
- Build the documentation
- Start a local server
- Run link validation
- Open at http://localhost:8000

## Style Guide

- Use Markdown format
- Include proper headings structure
- Add navigation links to related content
- Use code blocks for examples

## Review Process

All documentation changes go through:
1. Automated link validation
2. Peer review
3. Integration testing
4. Deployment to GitHub Pages

## Questions?

- Open an issue for questions
- Join our community discussions
- Check existing documentation first

## Related

- [Getting Started](../GETTING_STARTED.md)
- [Architecture Overview](../explanation/architecture-overview.md)