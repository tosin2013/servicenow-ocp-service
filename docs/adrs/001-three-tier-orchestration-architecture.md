# ADR-001: Three-Tier Orchestration Architecture

**Status:** Proposed

**Date:** 2025-09-05

## Context

The project requires a clear separation of concerns to manage the orchestration of OpenShift resources, handle user identities, and provision the actual infrastructure. This separation is crucial for maintainability, scalability, and security. The solution needs to leverage the strengths of each component in the technology stack.

## Decision

The architecture will be implemented as a three-tier system:

1.  **ServiceNow (Orchestration Tier):** Acts as the central orchestrator, hosting the master workflow, the Service Catalog item for initiating requests, and all associated business logic (approvals, notifications). It will be the single point of initiation for all provisioning activities.

2.  **Keycloak (Identity Tier):** Serves as the source of truth for user identities. The ServiceNow workflow will create new user accounts in Keycloak, and OpenShift will be configured to trust Keycloak as an external OpenID Connect (OIDC) identity provider.

3.  **OpenShift (Resource Tier):** Functions as the target platform where new projects are created. The ServiceNow workflow will interact with the OpenShift API to request new projects and to create RoleBindings that grant permissions to the users managed in Keycloak.

## Rationale

This layered approach provides a clear separation of concerns and aligns with the core competencies of each platform. ServiceNow excels at workflow orchestration and ITSM, Keycloak provides robust and flexible identity and access management, and OpenShift is a leading platform for containerized applications. By leveraging each platform for its intended purpose, we can create a solution that is both powerful and maintainable.

## Consequences

-   **Clear Separation of Duties:** Each tier has a well-defined responsibility, which simplifies development, testing, and maintenance.
-   **Improved Scalability:** Each tier can be scaled independently to meet demand.
-   **Enhanced Security:** The separation of tiers allows for more granular security controls and reduces the attack surface of each component.
-   **Increased Complexity:** The three-tier architecture introduces additional complexity in terms of deployment and configuration.
