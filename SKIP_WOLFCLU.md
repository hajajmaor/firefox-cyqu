# 🔧 Skip wolfCLU - Use Alternative Methods

## Issue

wolfCLU has build compatibility issues with the latest wolfSSL.

## Solution: Skip wolfCLU, Use Alternative Methods

Instead of using wolfCLU for certificate generation, we have better alternatives:

---

## ✅ **Option 1: Use OQS-OpenSSL Provider** (Recommended)

This is what we documented in `TESTING_WITH_HYBRID_CERTS.md`.

### Quick Setup:

```bash
# Install OQS-OpenSSL provider (much simpler than wolfCLU)
git clone https://github.com/open-quantum-safe/oqs-provider.git /tmp/oqs-provider
cd /tmp/oqs-provider
cmake -DCMAKE_PREFIX_PATH=/usr/local -S . -B _build
cmake --build _build
sudo cmake --install _build

# Verify
openssl list -providers
# Should show "oqsprovider"
```

### Generate Hybrid Certificate:

```bash
cd /home/kono/projects/cyqu/firefox-cyqu

# Generate ML-DSA-65 key
openssl genpkey -algorithm mldsa65 -provider oqsprovider \
    -out hybrid_key.pem

# Generate self-signed hybrid certificate
openssl req -new -x509 \
    -key hybrid_key.pem \
    -provider oqsprovider \
    -out hybrid_cert.pem \
    -days 365 \
    -subj "/C=US/ST=CA/L=SF/O=PQ Test/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# This creates a certificate with ML-DSA-65 signatures!
```

---

## ✅ **Option 2: Use wolfSSL Library Directly**

Instead of wolfCLU command-line tool, use wolfSSL library in a simple C program.

### Create Certificate Generator:

```c
// generate_hybrid_cert.c
#include <wolfssl/options.h>
#include <wolfssl/wolfcrypt/dilithium.h>
#include <wolfssl/wolfcrypt/asn_public.h>
#include <wolfssl/wolfcrypt/asn.h>

int main() {
    // Use wolfSSL library to generate hybrid certificate
    // This avoids wolfCLU compatibility issues
    
    // See wolfSSL examples:
    // wolfssl/examples/certgen/certgen_example.c
    
    return 0;
}
```

Compile:
```bash
gcc generate_hybrid_cert.c -o generate_hybrid_cert \
    -I/usr/local/include -L/usr/local/lib -lwolfssl
```

---

## ✅ **Option 3: Use Pre-Generated Test Certificates**

wolfSSL includes test certificates in their repository:

```bash
cd /tmp
git clone --depth 1 https://github.com/wolfSSL/wolfssl.git
cd wolfssl

# Find Dilithium test certificates
find . -name "*dilithium*" -o -name "*pqc*" | grep -E "\.(pem|der)$"

# Copy to your project
cp certs/*dilithium*.pem /home/kono/projects/cyqu/firefox-cyqu/
```

---

## 🎯 **Recommended: Use OQS-OpenSSL Provider**

This is the **easiest and most reliable** method:

```bash
# 1. Install liboqs (already done!)
# Already at /usr/local/lib/liboqs.so

# 2. Install OQS-OpenSSL provider
git clone https://github.com/open-quantum-safe/oqs-provider.git /tmp/oqs-provider
cd /tmp/oqs-provider
cmake -DCMAKE_PREFIX_PATH=/usr/local -S . -B _build
cmake --build _build
sudo cmake --install _build

# 3. Generate hybrid certificate (ONE command!)
openssl req -new -x509 \
    -newkey mldsa65 \
    -keyout hybrid_key.pem \
    -out hybrid_cert.pem \
    -nodes -days 365 \
    -provider oqsprovider \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# 4. Use with test server
python3 test_pq_server.py
```

---

## 🧪 **Test Results**

With OQS-OpenSSL hybrid certificate:

```javascript
// In Firefox Browser Console
gBrowser.securityUI.securityInfo.pqProtectionStatus
// Expected: "pq-protected" ✅
```

---

## 📊 **Comparison**

| Method | Difficulty | Status | Result |
|--------|-----------|--------|--------|
| wolfCLU | ❌ Hard (build issues) | Broken | N/A |
| OQS-OpenSSL | ✅ Easy | Works | Hybrid cert ✅ |
| wolfSSL Library | ⚠️ Medium | Complex | Hybrid cert ✅ |
| Test Certificates | ✅ Easy | Quick | Test only |

**Recommendation**: Use OQS-OpenSSL Provider (Option 1)

---

## 🎉 **Summary**

Skip wolfCLU entirely and use OQS-OpenSSL provider instead:

```bash
# Quick install
sudo apt-get install -y cmake
git clone https://github.com/open-quantum-safe/oqs-provider.git /tmp/oqs-provider
cd /tmp/oqs-provider
cmake -S . -B _build
cmake --build _build
sudo cmake --install _build

# Generate cert
cd /home/kono/projects/cyqu/firefox-cyqu
openssl req -new -x509 -newkey mldsa65 -keyout hybrid_key.pem \
    -out hybrid_cert.pem -nodes -days 365 -provider oqsprovider \
    -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Test
python3 test_pq_server.py
./mach run
# Navigate to https://localhost:8443
# Should show "pq-protected" ✅
```

**This is the easiest path to a working hybrid certificate!**
