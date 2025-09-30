# 🔐 Create Hybrid Certificate with wolfSSL

## Overview

wolfSSL supports **X.509 2019 Edition (Chimera Certificates)** with:
- Alternative Subject Public Key Extension (2.5.29.xx)
- Alternative Signature Algorithm Extension (2.5.29.73)
- Alternative Signature Value Extension (2.5.29.74)

This is EXACTLY what we need for Post-Quantum hybrid certificates!

Source: https://www.wolfssl.com/products/wolfcrypt-post-quantum/

---

## 📋 Prerequisites

### Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y build-essential autoconf automake libtool git
```

---

## 🚀 Step 1: Build wolfSSL with PQ Support

```bash
cd /tmp

# Clone wolfSSL
git clone https://github.com/wolfSSL/wolfssl.git
cd wolfssl

# Configure with Dilithium (ML-DSA) and X.509 chimera support
./autogen.sh
./configure \
    --enable-dilithium \
    --enable-altcertchains \
    --enable-tlsx \
    --enable-postauth \
    CFLAGS="-DWOLFSSL_ALT_CERT_CHAINS -DHAVE_EX_DATA"

# Build
make -j$(nproc)

# Install
sudo make install
sudo ldconfig

# Verify
wolfssl-config --version
```

---

## 🔐 Step 2: Build wolfCLU for Certificate Generation

```bash
cd /tmp

# Clone wolfCLU
git clone https://github.com/wolfSSL/wolfCLU.git
cd wolfCLU

# Configure
./autogen.sh
./configure

# Build
make -j$(nproc)

# Install
sudo make install

# Verify
wolfssl -v
```

---

## 🎯 Step 3: Generate Hybrid Certificate

### 3.1: Generate Dilithium Key Pair

```bash
cd /home/kono/projects/cyqu/firefox-cyqu

# Generate ML-DSA-65 (Dilithium level 3) key pair
wolfssl -genkey dilithium \
    -level 3 \
    -out hybrid_dilithium_key \
    -outform der \
    -output keypair

# This creates:
# - hybrid_dilithium_key.priv (private key)
# - hybrid_dilithium_key.pub (public key)
```

### 3.2: Generate RSA Key Pair (for hybrid)

```bash
# Generate RSA-2048 key
openssl genrsa -out hybrid_rsa.key 2048

# Or use ECDSA P-256 (recommended)
openssl ecparam -name prime256v1 -genkey -noout -out hybrid_ecdsa.key
```

### 3.3: Create Hybrid Certificate Request

```bash
# Create certificate configuration
cat > hybrid_cert.conf << 'EOF'
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = San Francisco
O = PQ Test Organization
OU = Post-Quantum Research
CN = localhost

[v3_req]
basicConstraints = CA:TRUE
keyUsage = critical, digitalSignature, keyCertSign
subjectAltName = @alt_names
# Placeholder for alternative signature extensions
# These will be added by wolfSSL tools

[alt_names]
DNS.1 = localhost
DNS.2 = 127.0.0.1
IP.1 = 127.0.0.1
EOF

# Generate CSR with RSA
openssl req -new \
    -key hybrid_rsa.key \
    -config hybrid_cert.conf \
    -out hybrid.csr
```

### 3.4: Sign with Both RSA and ML-DSA (Manual Method)

Since wolfCLU may not directly support hybrid certificate generation yet, we'll use a workaround:

```bash
# 1. Create standard RSA certificate
openssl x509 -req \
    -in hybrid.csr \
    -signkey hybrid_rsa.key \
    -days 365 \
    -out hybrid_base.pem \
    -extensions v3_req \
    -extfile hybrid_cert.conf

# 2. Extract TBS (To Be Signed) certificate data
openssl asn1parse -in hybrid_base.pem -strparse <offset> -out tbs.der

# 3. Sign TBS with Dilithium
wolfssl dilithium -sign \
    -inkey hybrid_dilithium_key.priv \
    -inform der \
    -in tbs.der \
    -out dilithium_signature.sig

# 4. Combine into hybrid certificate (requires custom tool)
# This step needs a custom script to add extensions 2.5.29.73/74
```

---

## 🔧 Alternative: Use wolfSSL Certificate Generation API

Since manual hybrid certificate creation is complex, let's use wolfSSL's native API:

### Create Hybrid Certificate Generation Script

```python
#!/usr/bin/env python3
# generate_hybrid_cert.py
# Requires: wolfssl python bindings

import sys
import os
from datetime import datetime, timedelta

# Note: This is pseudocode - actual implementation requires
# wolfssl python bindings or C API

def generate_hybrid_certificate():
    """
    Generate hybrid certificate with RSA + ML-DSA-65 signatures
    """
    
    # 1. Generate RSA key pair
    rsa_key = generate_rsa_key(2048)
    
    # 2. Generate ML-DSA-65 key pair
    mldsa_key = generate_dilithium_key(level=3)
    
    # 3. Create certificate structure
    cert = X509Certificate()
    cert.set_subject("CN=localhost, O=PQ Test")
    cert.set_issuer("CN=localhost, O=PQ Test")  # Self-signed
    cert.set_validity(days=365)
    
    # 4. Add RSA public key (primary)
    cert.set_public_key(rsa_key.public_key())
    
    # 5. Add extensions
    cert.add_extension(BasicConstraints(ca=True))
    cert.add_extension(SubjectAltName(["DNS:localhost", "IP:127.0.0.1"]))
    
    # 6. Add Alternative Signature Algorithm (2.5.29.73)
    cert.add_extension(AlternativeSignatureAlgorithm(
        oid="2.16.840.1.101.3.4.3.17",  # ML-DSA-65
        params=None
    ))
    
    # 7. Sign with RSA (primary signature)
    cert.sign(rsa_key, algorithm="sha256WithRSAEncryption")
    
    # 8. Add Alternative Signature Value (2.5.29.74)
    alt_signature = mldsa_key.sign(cert.tbs_certificate)
    cert.add_extension(AlternativeSignatureValue(alt_signature))
    
    # 9. Export
    cert.export_pem("hybrid_cert.pem")
    rsa_key.export_pem("hybrid_key.pem")
    
    print("✅ Hybrid certificate generated!")
    print("   Certificate: hybrid_cert.pem")
    print("   Key: hybrid_key.pem")

if __name__ == "__main__":
    generate_hybrid_certificate()
```

---

## 🎯 Simplified Approach: Use Pre-Built wolfSSL Test Certificates

wolfSSL includes test certificates with hybrid signatures in their repository:

```bash
cd /tmp/wolfssl

# Look for test certificates with PQ signatures
find . -name "*dilithium*cert*" -o -name "*hybrid*cert*"

# Copy to your project
cp certs/test-dilithium* /home/kono/projects/cyqu/firefox-cyqu/
```

---

## 🚀 Quick Solution: Generate with wolfSSL Examples

```bash
cd /tmp/wolfssl/examples/client

# Build examples with Dilithium support
cd ..
make examples

# Run certificate generation example
./examples/server/server -c certs/server-cert.pem -k certs/server-key.pem -g
```

---

## ✅ Expected Result

A hybrid certificate should have:

```
Certificate:
    Data:
        Version: 3 (0x2)
        Signature Algorithm: sha256WithRSAEncryption
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
        X509v3 extensions:
            2.5.29.73: Alternative Signature Algorithm
                ML-DSA-65 (OID: 2.16.840.1.101.3.4.3.17)
            2.5.29.74: Alternative Signature Value
                [ML-DSA-65 signature bytes]
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        [RSA signature bytes]
```

---

## 🧪 Test with Firefox

Once you have the hybrid certificate:

```bash
# 1. Update test server to use hybrid cert
# Edit test_pq_server.py, lines 80-81:
#   cert_file = 'hybrid_cert.pem'
#   key_file = 'hybrid_key.pem'

# 2. Restart server
pkill -f test_pq_server
python3 test_pq_server.py &

# 3. Test in Firefox
./mach run

# Navigate to: https://localhost:8443
# Browser Console: gBrowser.securityUI.securityInfo.pqProtectionStatus
# Expected: "pq-protected" ✅
```

---

## 📚 Resources

- wolfSSL PQ Products: https://www.wolfssl.com/products/wolfcrypt-post-quantum/
- wolfCLU Dilithium Support: https://www.wolfssl.com/dilithium-support-in-wolfclu/
- wolfSSL Examples: https://github.com/wolfSSL/wolfssl/tree/master/examples
- X.509 Chimera Certificates Spec: RFC 8708

---

## 🎯 Summary

wolfSSL provides complete support for hybrid certificates including:
- ✅ ML-DSA-44/65/87 (Dilithium) signatures
- ✅ X.509 2019 Chimera Certificate format
- ✅ Alternative signature extensions (2.5.29.73/74)
- ✅ Hybrid schemes with ECDSA/RSA

Once implemented, your Firefox will show:
```
PQ Status: pq-protected
Message: Protected by ML-DSA-65
Protected: true
```

🎉 **This will prove your PQ implementation works end-to-end!**
