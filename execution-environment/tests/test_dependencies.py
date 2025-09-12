# execution-environment/tests/test_dependencies.py
import sys
try:
    import yaml
    import requests
    import kubernetes
    import openshift
    print('✓ Python dependencies working')
    sys.exit(0)
except ImportError as e:
    print(f'✗ Failed to import a required Python dependency: {e}')
    sys.exit(1)
