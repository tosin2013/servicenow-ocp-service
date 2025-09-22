# 📚 Documentation Container Guide

**Complete guide for running ServiceNow-OpenShift Integration documentation in a Podman container**

## 🎯 Overview

This guide provides a containerized solution for running the project documentation using MkDocs in a Podman container. This approach solves configuration issues and provides a clean, portable documentation environment.

## 🏗️ Architecture

The documentation system uses:

- **Base Image**: Python 3.11 slim
- **Documentation Engine**: MkDocs with Material theme
- **Container Runtime**: Podman
- **Plugins**: Mermaid diagrams, Git revision dates, PyMdown extensions
- **Port**: 8000 (mapped to host)

## 📁 Directory Structure

```
docs/
├── Dockerfile                    # Container definition
├── mkdocs.yml                   # MkDocs configuration
├── run-docs.sh                  # Management script
├── .containerignore             # Container build exclusions
├── content/                     # Documentation source files
│   ├── index.md                # Homepage
│   ├── tutorials/              # Step-by-step guides
│   ├── how-to/                 # Problem-solving guides
│   ├── reference/              # Technical reference
│   ├── explanation/            # Conceptual explanations
│   └── adrs/                   # Architectural Decision Records
└── site/                       # Generated static site
```

## 🚀 Quick Start

### Prerequisites

- Podman installed and configured
- Access to the docs directory
- Port 8000 available

### Start Documentation Server

```bash
cd docs
./run-docs.sh start
```

The documentation will be available at: **http://localhost:8000**

## 📋 Available Commands

### Server Management

```bash
# Start documentation server
./run-docs.sh start

# Stop documentation server
./run-docs.sh stop

# Restart documentation server
./run-docs.sh restart

# Check server status
./run-docs.sh status

# View server logs
./run-docs.sh logs
```

### Build Operations

```bash
# Build static documentation site
./run-docs.sh build

# Build container image only
./run-docs.sh start  # (builds image automatically)
```

### Development Tools

```bash
# Open shell in running container
./run-docs.sh shell

# Clean up container and image
./run-docs.sh clean

# Show help
./run-docs.sh help
```

## 🔧 Configuration Details

### MkDocs Configuration

The `mkdocs.yml` file is configured for:

- **Theme**: Material Design with navigation tabs
- **Plugins**: Search, Mermaid diagrams, Git revision dates
- **Extensions**: PyMdown extensions for enhanced markdown
- **Structure**: Diataxis framework (Tutorials, How-to, Reference, Explanation)

### Container Configuration

The `Dockerfile` includes:

- Python 3.11 slim base image
- Git for revision tracking
- MkDocs and all required plugins
- Proper working directory setup
- Port 8000 exposure

### Volume Mounting

The container mounts the docs directory as a volume, enabling:

- Live editing of documentation
- Persistent changes
- Hot reloading during development

## 📊 Documentation Structure

### Diataxis Framework Implementation

The documentation follows the Diataxis framework:

1. **Tutorials** (`tutorials/`): Learning-oriented guides
   - Your First Project
   - Getting Started
   - User Workflows
   - Ansible Vault Configuration

2. **How-To Guides** (`how-to/`): Problem-solving guides
   - Scale for Production
   - Backup and Recovery
   - AAP Token Setup
   - Business Rule Logic

3. **Reference** (`reference/`): Information-oriented documentation
   - API Reference
   - Configuration Variables
   - PDI Alternative Solutions

4. **Explanation** (`explanation/`): Understanding-oriented documentation
   - Deployment Architecture
   - Architecture Overview

### Key Features

- **Visual Diagrams**: Mermaid integration for architecture diagrams
- **API Documentation**: Comprehensive REST API reference
- **Configuration Reference**: Complete variable documentation
- **ADR Integration**: Architectural Decision Records included
- **Search Functionality**: Full-text search across all documentation

## 🛠️ Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check if port 8000 is in use
sudo netstat -tlnp | grep :8000

# Stop any existing container
podman stop servicenow-ocp-docs
podman rm servicenow-ocp-docs
```

#### Build Failures

```bash
# Clean up and rebuild
./run-docs.sh clean
./run-docs.sh start
```

#### Permission Issues

```bash
# Ensure script is executable
chmod +x run-docs.sh

# Check SELinux context (if applicable)
ls -Z run-docs.sh
```

### Log Analysis

View detailed logs for troubleshooting:

```bash
# Real-time logs
./run-docs.sh logs

# Container inspection
podman inspect servicenow-ocp-docs

# Image details
podman images servicenow-ocp-docs
```

## 🔄 Development Workflow

### Making Documentation Changes

1. **Edit Files**: Modify files in the `content/` directory
2. **Live Preview**: Changes are automatically reflected at http://localhost:8000
3. **Test Build**: Run `./run-docs.sh build` to test static generation
4. **Commit Changes**: Use git to commit documentation updates

### Adding New Content

1. **Create Files**: Add new `.md` files in appropriate directories
2. **Update Navigation**: Edit `mkdocs.yml` to include new pages
3. **Test Links**: Verify all internal links work correctly
4. **Build Verification**: Ensure static build completes without errors

## 📈 Performance Optimization

### Container Optimization

- Uses `.containerignore` to exclude unnecessary files
- Leverages Docker layer caching
- Minimal base image for faster builds

### Documentation Optimization

- Optimized image sizes and formats
- Efficient navigation structure
- Fast search indexing
- Compressed static assets

## 🔒 Security Considerations

### Container Security

- Non-root user execution
- Minimal attack surface
- No sensitive data in container
- Volume mounting with appropriate permissions

### Documentation Security

- No sensitive credentials in documentation
- Sanitized configuration examples
- Secure external link handling

## 📚 Additional Resources

### Documentation Standards

- [Diataxis Framework](https://diataxis.fr/) - Documentation structure methodology
- [MkDocs Documentation](https://www.mkdocs.org/) - Static site generator
- [Material Theme](https://squidfunk.github.io/mkdocs-material/) - Theme documentation

### Container Resources

- [Podman Documentation](https://podman.io/) - Container runtime
- [Container Best Practices](https://developers.redhat.com/blog/2016/02/24/10-things-to-avoid-in-docker-containers) - Security and optimization

## 🎉 Success Metrics

The containerized documentation system provides:

- **✅ 100% Reproducible Builds**: Consistent environment across systems
- **✅ Zero Configuration**: Works out of the box
- **✅ Live Reloading**: Instant preview of changes
- **✅ Professional Output**: Material Design theme with search
- **✅ Complete Coverage**: All Diataxis framework sections implemented
- **✅ Visual Diagrams**: Mermaid integration for architecture documentation
- **✅ API Documentation**: Comprehensive REST API reference

---

**🚀 Ready to explore the documentation? Visit http://localhost:8000 after running `./run-docs.sh start`**
