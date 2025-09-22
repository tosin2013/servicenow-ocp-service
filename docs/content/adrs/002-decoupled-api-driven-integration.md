# ADR-002: Decoupled, API-Driven Integration

**Status:** Proposed

**Date:** 2025-09-05

## Context

The integration between ServiceNow, Keycloak, and OpenShift must be resilient to changes in the underlying implementation of each platform. A tightly coupled integration would be brittle and difficult to maintain. Furthermore, the authentication mechanisms for each integration point need to be secure and appropriate for the context of the interaction.

## Decision

All communication between the three tiers will be conducted via their respective REST APIs, and the authentication mechanisms for each integration point will be decoupled:

-   **ServiceNow to Keycloak:** Communication will be secured using the OAuth 2.0 Client Credentials grant type. ServiceNow will be registered as a confidential client in Keycloak and will use its client ID and secret to obtain a Bearer Token for authenticating its API requests.

-   **ServiceNow to OpenShift:** Communication will be secured using a long-lived Bearer Token from an OpenShift Service Account. A dedicated Service Account will be created in OpenShift for ServiceNow, and it will be granted the minimum necessary permissions via OpenShift's Role-Based Access Control (RBAC) system.

-   **OpenShift to Keycloak:** This trust relationship will be established by configuring OpenShift to use Keycloak as an OIDC identity provider. This allows users to log in to OpenShift using their Keycloak credentials and enables OpenShift's RBAC system to recognize and bind roles to Keycloak-managed identities.

## Rationale

An API-driven approach ensures a clean, loosely coupled architecture that is resilient to changes in the underlying implementation of each platform. Decoupling the authentication mechanisms enhances security by allowing each system to use the most appropriate and secure method for its specific context.

## Consequences

-   **Increased Resilience:** The loose coupling provided by the API-driven approach makes the system more resilient to changes in individual components.
-   **Enhanced Security:** Decoupled authentication allows for the use of the most secure and appropriate authentication mechanism for each integration point.
-   **Improved Maintainability:** The clear separation of concerns and the use of well-defined APIs make the system easier to maintain and troubleshoot.
-   **Dependency on APIs:** The solution is dependent on the stability and availability of the APIs of all three platforms.
