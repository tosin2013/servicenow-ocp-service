# Software Bill of Materials (SBOM)

**Image**: `quay.io/takinosh/servicenow-ocp-ee:test-hub-version-1758139175`  
**Built**: 2025-09-17T20:02:51Z  
**Git SHA**: f858e0f7ee1ab397a4843b554b4e30b4f3f0e90e

## Base Image
- Red Hat Universal Base Image (UBI) 9

## Ansible Collections

### Collections from requirements.yml
- redhat_cop.aap_utilities  # aap
- ansible.platform  # aap (pulls kubernetes.core; requires openshift-clients on RHEL)
- ansible.hub
- ansible.controller  # aap
- kubernetes.core  # containers
- community.general
- redhat.sso  # sso
- ansible.utils  # general

### Python Packages
- ara
