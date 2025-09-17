#!/usr/bin/env python3
"""
Filter script to remove conflicting packages from bindep output.
This script processes the generated bindep file to remove packages that
conflict with our manual installation methods (like openshift-clients via tarball).
"""
import sys
import re

def filter_bindep_file(input_file, output_file):
    """Filter conflicting packages from bindep file."""
    exclude_patterns = [
        r'openshift-clients.*platform:rhel-[89]',
        # Add other patterns as needed
    ]
    
    filtered_lines = []
    
    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                filtered_lines.append(line)
                continue
                
            # Check if line matches any exclusion pattern
            should_exclude = False
            for pattern in exclude_patterns:
                if re.search(pattern, line):
                    should_exclude = True
                    # Add comment explaining why it was excluded
                    filtered_lines.append(f"# FILTERED: {line}  # Installed via tarball, not package manager")
                    break
            
            if not should_exclude:
                filtered_lines.append(line)
    
    with open(output_file, 'w') as f:
        for line in filtered_lines:
            f.write(line + '\n')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: bindep-filter.py <input_file> <output_file>")
        sys.exit(1)
    
    filter_bindep_file(sys.argv[1], sys.argv[2])
    print(f"Filtered bindep file: {sys.argv[1]} -> {sys.argv[2]}")