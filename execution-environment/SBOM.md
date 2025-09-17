# Software Bill of Materials (SBOM)

**Image**: `quay.io/takinosh/servicenow-ocp-ee:test-shell-fix-1758141209`  
**Built**: 2025-09-17T20:34:20Z  
**Git SHA**: 0d539b13c009d36b250ccadec9b1af34a2f722dd

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
