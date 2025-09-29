# 🧪 Testing Firefox PQ with Hybrid Certificates

**Goal**: Generate hybrid certificates with ML-DSA signatures and test against your Firefox build

---

## 🎯 **Overview**

To test your PQ implementation, you need:
1. ✅ Hybrid certificate chain (Root CA → Intermediate → Server cert)
2. ✅ Web server configured with hybrid certs
3. ✅ Firefox trusting your test CA
4. ✅ liboqs installed (for real verification)

---

## 📋 **Prerequisites**

### Option A: Using OpenSSL with OQS Provider (Recommended)

Install OpenSSL with OQS support:

```bash
# 1. Install liboqs first (if not done)
cd /home/kono/projects/cyqu/firefox-cyqu/security/third_party/liboqs
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      ..
make -j$(nproc)
sudo make install
sudo ldconfig

# 2. Install OQS-OpenSSL provider
cd /tmp
git clone https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider
cmake -DCMAKE_PREFIX_PATH=/usr/local -S . -B _build
cmake --build _build
sudo cmake --install _build

# 3. Verify installation
openssl list -providers
# Should show "oqsprovider" in the list
```

### Option B: Using EJBCA (Enterprise Grade)

Download and configure EJBCA Community Edition:
- https://www.ejbca.org/
- Supports hybrid certificates natively
- More complex but production-ready

---

## 🔐 **Method 1: Quick Test with OpenSSL + OQS Provider**

### Step 1: Generate Hybrid Root CA

Create a configuration file for hybrid certificates:

```bash
cat > hybrid-ca.conf << 'EOF'
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
C = US
ST = California
L = Mountain View
O = Test PQ CA
OU = Cryptography Research
CN = Test PQ Root CA

[ v3_ca ]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
# Alternative Signature extensions will be added via command line
EOF
```

Generate hybrid root CA (RSA + ML-DSA-65):

```bash
# Generate RSA key
openssl genrsa -out root-rsa.key 2048

# Generate ML-DSA-65 key
openssl genpkey -algorithm mldsa65 -provider oqsprovider -out root-mldsa65.key

# Create root certificate with RSA
openssl req -new -x509 -days 3650 -key root-rsa.key \
  -config hybrid-ca.conf -out root-cert.pem

# Sign with ML-DSA-65 (alternative signature)
# This creates the hybrid certificate with both signatures
openssl x509 -req -in root-cert.pem \
  -CA root-cert.pem -CAkey root-mldsa65.key \
  -provider oqsprovider \
  -out root-hybrid.pem -days 3650 \
  -copy_extensions copy
```

### Step 2: Generate Hybrid Server Certificate

```bash
# Server cert configuration
cat > server.conf << 'EOF'
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
C = US
ST = California
L = Mountain View
O = Test PQ Server
CN = localhost

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
DNS.2 = 127.0.0.1
IP.1 = 127.0.0.1
EOF

# Generate server keys
openssl genrsa -out server-rsa.key 2048
openssl genpkey -algorithm mldsa65 -provider oqsprovider -out server-mldsa65.key

# Generate CSR with RSA
openssl req -new -key server-rsa.key -config server.conf -out server.csr

# Sign with Root CA (RSA)
openssl x509 -req -in server.csr -days 365 \
  -CA root-cert.pem -CAkey root-rsa.key \
  -CAcreateserial -out server-cert.pem \
  -extensions v3_req -extfile server.conf

# Add ML-DSA alternative signature
openssl x509 -req -in server.csr -days 365 \
  -CA root-hybrid.pem -CAkey root-mldsa65.key \
  -provider oqsprovider \
  -out server-hybrid.pem \
  -copy_extensions copy
```

---

## 🌐 **Method 2: Simple Python HTTPS Server**

### Create Test Web Server

```python
#!/usr/bin/env python3
# test_pq_server.py

import http.server
import ssl
import socket

# Configuration
PORT = 8443
CERTFILE = 'server-hybrid.pem'
KEYFILE = 'server-rsa.key'

class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>PQ Certificate Test</title>
            <style>
                body { font-family: Arial; margin: 40px; }
                .success { color: green; font-weight: bold; }
                .info { background: #f0f0f0; padding: 20px; margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>🔐 Post-Quantum Certificate Test Server</h1>
            <p class="success">✅ Connection successful!</p>
            
            <div class="info">
                <h2>Certificate Information:</h2>
                <ul>
                    <li>Classical Algorithm: RSA-2048</li>
                    <li>Post-Quantum Algorithm: ML-DSA-65 (Dilithium-3)</li>
                    <li>Extensions: 2.5.29.73 (Alt Signature Algorithm)</li>
                    <li>Extensions: 2.5.29.74 (Alt Signature Value)</li>
                </ul>
            </div>
            
            <div class="info">
                <h2>Test in Firefox Console:</h2>
                <pre>
let secInfo = gBrowser.securityUI.securityInfo;
console.log("PQ Status:", secInfo.pqProtectionStatus);
console.log("Message:", secInfo.pqStatusMessage);
console.log("Protected:", secInfo.isPQProtected);
                </pre>
                <p>Expected: <strong>pq-protected</strong> ✅</p>
            </div>
            
            <h2>Next Steps:</h2>
            <ol>
                <li>Check the lock icon in Firefox</li>
                <li>Open Browser Console (Ctrl+Shift+J)</li>
                <li>Run the test commands above</li>
                <li>You should see "PQ Protected" status!</li>
            </ol>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

# Create HTTPS server
httpd = http.server.HTTPServer(('localhost', PORT), SimpleHTTPRequestHandler)

# Configure SSL with hybrid certificate
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(CERTFILE, KEYFILE)

httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print(f"🚀 PQ Test Server running on https://localhost:{PORT}")
print(f"📜 Using certificate: {CERTFILE}")
print(f"🔑 Using key: {KEYFILE}")
print("\n⚠️  Remember to:")
print("   1. Install root-hybrid.pem in Firefox (Settings → Privacy → Certificates → Import)")
print("   2. Enable liboqs in Firefox (uncomment ml_dsa.c implementation)")
print("   3. Rebuild Firefox: ./mach build\n")
print("Press Ctrl+C to stop\n")

httpd.serve_forever()
```

### Run the Server

```bash
chmod +x test_pq_server.py
python3 test_pq_server.py
```

---

## 🦊 **Configure Firefox to Trust Test CA**

### Step 1: Import Root Certificate

1. Open Firefox
2. Go to: `about:preferences#privacy`
3. Scroll down to "Certificates" → Click "View Certificates"
4. Go to "Authorities" tab
5. Click "Import..."
6. Select `root-hybrid.pem`
7. Check "Trust this CA to identify websites"
8. Click OK

### Step 2: Enable liboqs in Firefox

```bash
cd /home/kono/projects/cyqu/firefox-cyqu

# Uncomment real ML-DSA implementation
# Edit security/nss/lib/freebl/ml_dsa.c
# Line 26: Uncomment #include <oqs/oqs.h>
# Lines 239-269: Uncomment OQS_SIG function calls
# Lines 335-362: Uncomment OQS_SIG function calls

# Rebuild
./mach build
```

### Step 3: Test!

```bash
# Run Firefox
./mach run

# Visit: https://localhost:8443
```

---

## 🧪 **Method 3: Using Nginx (Production-Like)**

### Install Nginx with OQS Support

```bash
# Install dependencies
sudo apt-get install -y nginx

# Configure Nginx
sudo cat > /etc/nginx/sites-available/pq-test << 'EOF'
server {
    listen 8443 ssl;
    server_name localhost;

    ssl_certificate /path/to/server-hybrid.pem;
    ssl_certificate_key /path/to/server-rsa.key;
    
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/pq-test;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/pq-test /etc/nginx/sites-enabled/
sudo mkdir -p /var/www/pq-test

# Create test page
sudo cat > /var/www/pq-test/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PQ Test Site</title>
</head>
<body>
    <h1>🔐 Post-Quantum Protected Site</h1>
    <p>This site uses hybrid ML-DSA-65 + RSA signatures!</p>
    <p>Check Firefox console for PQ status.</p>
</body>
</html>
EOF

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

## 📊 **Verify Hybrid Certificate Structure**

Check if certificate has alternative signature extensions:

```bash
# View certificate details
openssl x509 -in server-hybrid.pem -text -noout

# Look for:
# - Extension: 2.5.29.73 (Alternative Signature Algorithm)
# - Extension: 2.5.29.74 (Alternative Signature Value)

# Check with NSS certutil
certutil -d sql:$HOME/.mozilla/firefox/*.default-release -L -n "Test PQ Root CA" -a
```

---

## 🧪 **Testing Checklist**

### Before Testing
- [ ] liboqs installed
- [ ] OQS OpenSSL provider installed (or EJBCA ready)
- [ ] Hybrid certificates generated
- [ ] Root CA imported in Firefox
- [ ] Firefox rebuilt with uncommented ML-DSA code
- [ ] Test server running

### During Test
1. [ ] Visit `https://localhost:8443`
2. [ ] Click lock icon - should show secure connection
3. [ ] Open console (Ctrl+Shift+J)
4. [ ] Run PQ status check:
   ```javascript
   let secInfo = gBrowser.securityUI.securityInfo;
   console.log("Status:", secInfo.pqProtectionStatus);
   ```
5. [ ] Should show: `"pq-protected"` ✅

### Expected Results
- ✅ Connection succeeds
- ✅ `pqProtectionStatus === "pq-protected"`
- ✅ `pqStatusMessage === "Protected by ML-DSA-65"`
- ✅ `isPQProtected === true`
- ✅ Certificate shows extensions 2.5.29.73 and 2.5.29.74

---

## 🐛 **Troubleshooting**

### Issue: "pq-missing" instead of "pq-protected"

**Cause**: Certificate doesn't have alternative signature extensions

**Fix**:
1. Verify certificate has extensions 2.5.29.73/74:
   ```bash
   openssl x509 -in server-hybrid.pem -text | grep -A5 "2.5.29.7[34]"
   ```
2. If missing, regenerate with proper OQS tools

### Issue: "pq-verify-failed"

**Cause**: ML-DSA signature verification failed

**Fix**:
1. Check liboqs is installed: `ldconfig -p | grep liboqs`
2. Verify Firefox was rebuilt with uncommented code
3. Check certificate chain is complete

### Issue: Certificate not trusted

**Fix**:
1. Import root CA in Firefox
2. Clear SSL state: `about:preferences#privacy` → Clear Data → Certificates
3. Restart Firefox

---

## 🚀 **Quick Start (TL;DR)**

```bash
# 1. Install liboqs
cd security/third_party/liboqs/build
cmake .. && make && sudo make install

# 2. Install OQS OpenSSL provider
git clone https://github.com/open-quantum-safe/oqs-provider.git /tmp/oqs-provider
cd /tmp/oqs-provider
cmake -S . -B _build && cmake --build _build && sudo cmake --install _build

# 3. Generate hybrid certificates
# (Use scripts above or EJBCA)

# 4. Start test server
python3 test_pq_server.py

# 5. Import CA in Firefox
# Settings → Certificates → Import root-hybrid.pem

# 6. Uncomment liboqs code in ml_dsa.c

# 7. Rebuild Firefox
./mach build && ./mach run

# 8. Visit https://localhost:8443

# 9. Test in console:
# let secInfo = gBrowser.securityUI.securityInfo;
# console.log(secInfo.pqProtectionStatus); // Should be "pq-protected" ✅
```

---

## 📚 **Additional Resources**

### Certificate Generation Tools
- **OQS-OpenSSL**: https://github.com/open-quantum-safe/oqs-provider
- **EJBCA**: https://www.ejbca.org/
- **OQS-BoringSSL**: https://github.com/open-quantum-safe/boringssl

### Test Vectors
- **NIST FIPS-204**: ML-DSA test vectors
- **OQS Test Data**: https://github.com/open-quantum-safe/oqs-provider/tree/main/test

### Documentation
- **IETF LAMPS Draft**: Hybrid certificates specification
- **liboqs Docs**: https://github.com/open-quantum-safe/liboqs/wiki

---

## ✅ **Success Criteria**

When everything works:
1. ✅ Firefox connects without warnings
2. ✅ Lock icon shows secure connection
3. ✅ Console shows `pqProtectionStatus: "pq-protected"`
4. ✅ Message says "Protected by ML-DSA-65"
5. ✅ `isPQProtected === true`

**You'll have proven your PQ implementation works end-to-end!** 🎉

---

**Next**: Generate certificates and test your implementation!
