#!/usr/bin/env python3

import json
import subprocess
import sys
import os

def get_terraform_output():
    try:
        terraform_dir = "/home/terraform_ansible/2week/terraform"
        
        result = subprocess.run(['terraform', 'output', '-json'], 
                                cwd=terraform_dir, 
                                capture_output=True, 
                                text=True, 
                                check=True)
        print(f"Terraform output: {result.stdout}", file=sys.stderr)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running 'terraform output': {e}", file=sys.stderr)
        print(f"Stderr: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ['--list', '--host']:
        print("Usage: terraform_inventory.py --list|--host", file=sys.stderr)
        sys.exit(1)

    terraform_output = get_terraform_output()
    instance_ips = terraform_output.get('instance_public_ips', {}).get('value', [])

    print(f"Found instance IPs: {instance_ips}", file=sys.stderr)

    if sys.argv[1] == '--list':
        inventory = {
            'all': {
                'hosts': instance_ips
            },
            'example_instance': {
                'hosts': instance_ips
            },
            '_meta': {
                'hostvars': {}
            }
        }
        print(json.dumps(inventory))
    elif sys.argv[1] == '--host':
        print(json.dumps({}))

if __name__ == '__main__':
    main()