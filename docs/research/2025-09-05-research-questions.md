# Research Questions: ServiceNow to OpenShift Project Provisioning

**Date:** 2025-09-05

This document tracks key research questions for the project. The goal is to investigate these areas to ensure a secure, resilient, and maintainable solution.

**Target Versions:**
*   **ServiceNow:** Zurich
*   **OpenShift:** 4.18

---

## Architectural Context (Summary of ADRs)

Before addressing the research questions, it is important to understand the key architectural decisions that have been made. The following is a summary of the governing Architectural Decision Records (ADRs):

*   **ADR-001: Three-Tier Orchestration Architecture:** The system is divided into three distinct layers. **ServiceNow** is the Orchestration Tier for workflows and approvals. **Keycloak** is the Identity Tier, managing users. **OpenShift** is the Resource Tier where projects are created.
*   **ADR-002: Decoupled, API-Driven Integration:** All communication between the tiers is handled via REST APIs. ServiceNow authenticates to Keycloak using OAuth 2.0 and to OpenShift using a Service Account Bearer Token.
*   **ADR-003: Centralized Configuration:** All credentials and API endpoints are stored securely within ServiceNow using its "Connection & Credential Aliases" feature, avoiding hardcoded values in the workflows.
*   **ADR-004: GitOps Deployment:** Any components running on OpenShift will be deployed and managed using a GitOps workflow with ArgoCD and Kustomize.
*   **ADR-005: Keycloak Deployment via Operator:** Keycloak will be deployed and managed on the OpenShift cluster using the official Keycloak Operator, which aligns with the GitOps strategy.
*   **ADR-006: ServiceNow Implementation with Flow Designer:** The orchestration logic in ServiceNow will be built using the modern, low-code **Flow Designer** and **IntegrationHub**, not legacy workflows or custom scripts.

---

### Category 1: Security & Credential Management

-   [ ] **SN-SEC-01:** What is the most secure method for storing the OpenShift Service Account token and Keycloak Client Secret within ServiceNow Zurich, in alignment with ADR-003?
-   [ ] **SN-SEC-02:** How can we implement the principle of least privilege for the permissions granted to the ServiceNow Service Account in OpenShift 4.18? What are the absolute minimum roles/permissions required?
-   [ ] **SN-SEC-03 (GitOps):** How will sensitive information (e.g., API endpoints for different environments, credentials if any) be managed in the Git repository for ArgoCD? Should we use a tool like Sealed Secrets or Vault with OpenShift 4.18?
-   [ ] **SN-SEC-04:** What is the recommended credential rotation policy for the OpenShift Service Account token and the Keycloak client secret, and how can this be automated or managed within ServiceNow Zurich?

---

### Category 2: API Interaction & Error Handling

-   [ ] **API-EH-01:** What are the specific API rate limits for the Keycloak Admin API and the OpenShift 4.18 API? How should the ServiceNow Flow Designer workflow handle potential rate-limiting errors?
-   [ ] **API-EH-02:** What is the comprehensive list of potential failure points in the sequence diagram (e.g., user already exists, project name conflict, network timeout, invalid token)?
-   [ ] **API-EH-03:** For each failure point identified in `API-EH-02`, what is the desired compensating action or rollback procedure within Flow Designer? (e.g., if project creation succeeds but RoleBinding fails, should the project be deleted?)
-   [ ] **API-EH-04:** Are the Keycloak and OpenShift API calls idempotent? Can the Flow Designer workflow be safely retried upon failure without creating duplicate resources?
-   [ ] **API-EH-05 (Versions):** Are there any known breaking changes or considerations for the REST APIs in OpenShift 4.18 or ServiceNow Zurich that would impact the integration logic?

---

### Category 3: Deployment & Operations (ArgoCD/Kustomize & Keycloak Operator)

-   [ ] **OPS-GIT-01:** What is the optimal Kustomize overlay structure for managing configuration differences between development, staging, and production environments for the Keycloak Operator and any other integration-specific resources?
-   [ ] **OPS-GIT-02:** How will the ArgoCD Application resource be configured to monitor the Git repository? What sync policy (e.g., automated, manual) and sync options (e.g., Prune, SelfHeal) should be used?
-   [ ] **OPS-GIT-03:** What are the necessary health checks ArgoCD should use to determine if the Keycloak instance deployed by the operator is healthy?
-   [ ] **OPS-GIT-04:** What is the process for promoting a configuration change (e.g., a Keycloak realm update) from a development branch to the main branch that ArgoCD monitors for production?
-   [ ] **OPS-KC-01:** What is the recommended version of the Keycloak Operator for managing Keycloak on OpenShift 4.18?
-   [ ] **OPS-KC-02:** How should Keycloak be configured for high availability and data persistence (database) within the OpenShift 4.18 cluster?

---

### Category 4: Testing & Validation

-   [ ] **TEST-01:** What is the most effective strategy for automated end-to-end testing? Can we create a test suite that triggers a ServiceNow request (via API) and then uses the Keycloak and OpenShift APIs to validate the results?
-   [ ] **TEST-02:** How can we effectively simulate failure scenarios (e.g., Keycloak API being down, OpenShift returning a 500 error) to test the resilience and error-handling logic of the ServiceNow Flow Designer workflow?
-   [ ] **TEST-03:** What automated checks can be put in place to validate that the Keycloak user has the correct roles and the OpenShift RoleBinding is correctly applied?

---

### Category 5: Performance & Scalability

-   [ ] **PERF-01:** What is the baseline performance for a single end-to-end provisioning request (from submission to user notification)?
-   [ ] **PERF-02:** How does the system perform under a load of N concurrent requests? What are the primary bottlenecks (ServiceNow Flow Designer, Keycloak, OpenShift API)?
-   [ ] **PERF-03:** Is there a need for caching any data in ServiceNow to reduce API calls to Keycloak or OpenShift?
