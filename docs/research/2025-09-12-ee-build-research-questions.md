# Research Questions: Optimizing Ansible Execution Environment Build Process

**Date:** 2025-09-12

This document outlines key research questions aimed at improving the reliability, performance, and security of the custom Ansible Execution Environment (EE) build process.

### Category 1: Build Reliability & Reproducibility

*   **RQ1.1 (Base Image Strategy):** What are the trade-offs (e.g., security, stability, size, authentication complexity) between using the current Red Hat UBI8 base image versus alternative public images like `quay.io/ansible/ansible-runner` or `centos:stream9` for our CI/CD pipeline?
*   **RQ1.2 (Dependency Pinning):** How can we implement dependency pinning for Python (`pip-compile`, `poetry`) and Ansible Collections (`ansible-galaxy collection install --requirements-file` with version specs) to ensure perfectly reproducible builds?
*   **RQ1.3 (CLI Tool Versioning):** What is the most robust method for installing a *specific* version of the `oc` CLI to prevent unexpected breakages when the `stable` tag is updated?
*   **RQ1.4 (Build Validation):** How can we create an automated pre-build validation or linting step for `execution-environment.yml` to catch schema and syntax errors before the main build process begins?

### Category 2: Build Performance & Efficiency

*   **RQ2.1 (Layer Caching):** What is the optimal strategy for ordering our `dnf install`, `COPY`, and `RUN` commands in the `additional_build_steps` to maximize Podman's layer caching and significantly reduce build times for iterative development?
*   **RQ2.2 (Multi-Stage Builds):** Could a multi-stage build process be used to reduce the final image size by separating build-time dependencies (like `gcc`) from the final runtime environment?
*   **RQ2.3 (Dependency Installation):** What is the performance difference between installing system packages via `bindep.txt` versus a consolidated `dnf install` command in the `prepend_base` step?

### Category 3: Security Hardening

*   **RQ3.1 (Non-Root Build):** At what is the earliest possible stage in the Containerfile build process can we switch to a non-root user (`USER 1001`) without compromising the installation of necessary packages?
*   **RQ3.2 (Base Image Source):** What are the security implications of the build process requiring credentials for `registry.redhat.io` within a GitHub Actions workflow, and what are the best practices for managing these long-lived secrets?
*   **RQ3.3 (Error Handling):** How should commands that might fail (like `COPY custom-ca-certs/`) be handled? Is ignoring failures with `|| true` the correct security posture, or should the build fail with a clear error message?
