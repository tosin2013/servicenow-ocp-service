# MkDocs Documentation Container
FROM python:3.11-slim

# Set working directory
WORKDIR /docs

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install MkDocs and plugins
RUN pip install --no-cache-dir \
    mkdocs==1.5.3 \
    mkdocs-material==9.4.6 \
    mkdocs-mermaid2-plugin==1.1.1 \
    mkdocs-git-revision-date-localized-plugin==1.2.0 \
    pymdown-extensions==10.3.1

# Copy documentation files
COPY . /docs/

# Expose MkDocs development server port
EXPOSE 8000

# Default command to serve documentation
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
