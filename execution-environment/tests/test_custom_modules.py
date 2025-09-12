# execution-environment/tests/test_custom_modules.py
import sys
sys.path.append('/opt/ansible/custom-modules')
try:
    import servicenow_connection_alias
    import openshift_project_with_rbac
    print('✓ Custom modules can be imported')
    sys.exit(0)
except ImportError as e:
    print(f'✗ Failed to import custom modules: {e}')
    sys.exit(1)
