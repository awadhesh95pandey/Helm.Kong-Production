#!/bin/bash

# Get JWKS from Auth0
JWKS=$(curl -s https://devtush4r.us.auth0.com/.well-known/jwks.json)

# Extract the first key
KEY=$(echo "$JWKS" | jq -r '.keys[0]')

# Extract n and e values
N=$(echo "$KEY" | jq -r '.n')
E=$(echo "$KEY" | jq -r '.e')

# Create a temporary Python script to convert to PEM
cat > /tmp/jwks_to_pem.py << 'EOF'
import sys
import json
import base64

def base64url_decode(input):
    """Decode base64url string"""
    rem = len(input) % 4
    if rem > 0:
        input += '=' * (4 - rem)
    return base64.urlsafe_b64decode(input)

def jwks_to_pem(n, e):
    """Convert JWKS RSA key to PEM format"""
    from Crypto.PublicKey import RSA
    from Crypto.Util.number import bytes_to_long
    
    # Decode base64url encoded values
    n_bytes = base64url_decode(n)
    e_bytes = base64url_decode(e)
    
    # Convert to integers
    n_int = bytes_to_long(n_bytes)
    e_int = bytes_to_long(e_bytes)
    
    # Create RSA key
    key = RSA.construct((n_int, e_int))
    
    # Export as PEM
    return key.export_key().decode()

# Read n and e from command line
import os
n = os.environ.get('N')
e = os.environ.get('E')

if n and e:
    try:
        pem = jwks_to_pem(n, e)
        print(pem)
    except Exception as ex:
        print(f"Error: {ex}", file=sys.stderr)
        sys.exit(1)
EOF

# Try to run with Python and pycryptodome
N="$N" E="$E" python3 /tmp/jwks_to_pem.py 2>/dev/null

# If that fails, try with openssl approach
if [ $? -ne 0 ]; then
    echo "Python approach failed, trying openssl..."
    
    # Create ASN.1 DER format manually
    # This is complex, so let's just use the certificate from Auth0
    curl -s https://devtush4r.us.auth0.com/pem | openssl x509 -pubkey -noout
fi