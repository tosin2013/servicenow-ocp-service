# Troubleshooting Reference

This page provides comprehensive troubleshooting information for the ServiceNow-OpenShift integration.

## Common Issues

### Authentication Issues
- Problem: User cannot authenticate
- Solution: Check Keycloak configuration and user permissions

### ServiceNow Integration Issues
- Problem: Requests not being processed
- Solution: Verify ServiceNow business rules and API connectivity

### OpenShift Issues
- Problem: Projects not being created
- Solution: Check OpenShift permissions and resource quotas

## Debugging Steps

1. Check logs in Ansible Automation Platform
2. Verify ServiceNow request state
3. Validate OpenShift project creation
4. Test authentication flow

## Related Documentation

- [Debugging Integration Issues](../how-to/debugging-integration-issues.md)
- [End-to-End Testing](../how-to/end-to-end-testing.md)