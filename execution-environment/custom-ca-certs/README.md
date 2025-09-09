# Custom CA Certificates Directory

This directory contains custom CA certificates that will be added to the execution environment's trust store.

## Usage

1. Place any custom CA certificates (`.crt` or `.pem` files) in this directory
2. The execution environment build process will automatically copy these certificates to `/etc/pki/ca-trust/source/anchors/`
3. The `update-ca-trust` command will be run to update the system trust store

## Examples

- Corporate proxy certificates
- Internal PKI root certificates  
- Custom service certificates

## Security Note

Only place trusted certificates in this directory. All certificates will be trusted by applications running in the execution environment.
