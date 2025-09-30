# 🚀 How to Run the Test Server

## Quick Command

```bash
python3 test_pq_server.py
```

But first, you need certificate files!

---

## 📋 Prerequisites: Generate Certificate

The server needs `hybrid-cert.pem` and `hybrid-key.pem`.

### Option 1: Quick RSA Certificate (30 seconds) ⚡

**Use this to test the API immediately:**

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout hybrid-key.pem -out hybrid-cert.pem -days 365 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

**Result:** Shows `"pq-missing"` (correct for RSA-only cert) ✅

---

### Option 2: Hybrid Certificate with ML-DSA (requires setup) 🔐

**Use this for full PQ testing:**

1. **Rebuild liboqs with ML-DSA:**
   ```bash
   sudo ./fix_liboqs_mldsa.sh
   ```

2. **Rebuild OQS-OpenSSL provider:**
   ```bash
   sudo ./rebuild_oqs_provider.sh
   ```

3. **Generate hybrid certificate:**
   ```bash
   openssl req -new -x509 -newkey mldsa65 \
       -keyout hybrid-key.pem -out hybrid-cert.pem \
       -nodes -days 365 \
       -provider-path /usr/lib/x86_64-linux-gnu/ossl-modules \
       -provider oqsprovider -provider default \
       -subj "/CN=localhost" \
       -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
   ```

**Result:** Shows `"pq-protected"` ✅

---

## 🎯 Complete Testing Flow

### 1. Generate Certificate (choose Option 1 or 2 above)

### 2. Start Test Server

```bash
python3 test_pq_server.py
```

You should see:
```
🚀 PQ Test Server Starting...
🌐 URL: https://localhost:8443
📜 Certificate: hybrid-cert.pem
🔑 Key: hybrid-key.pem

💡 Visit the URL in Firefox to test PQ implementation
⏹️  Press Ctrl+C to stop
```

### 3. Open Firefox

```bash
./mach run
```

Or if already built:
```bash
./obj-x86_64-pc-linux-gnu/dist/bin/firefox
```

### 4. Navigate to Test Server

In Firefox, go to: **https://localhost:8443**

Click **Advanced → Accept the Risk and Continue** (self-signed cert warning)

### 5. Test in Browser Console

Press **Ctrl+Shift+J** (Browser Console, NOT F12 Web Console!)

Run this code:
```javascript
(() => {
  let win = Services.wm.getMostRecentWindow("navigator:browser");
  let browser = win.gBrowser.selectedBrowser;
  let secInfo = browser.securityUI.securityInfo;
  
  console.log("✅ PQ Status:", secInfo.pqProtectionStatus);
  console.log("✅ Message:", secInfo.pqStatusMessage);
  console.log("✅ Protected:", secInfo.isPQProtected);
})();
```

### 6. Expected Results

**With RSA certificate (Option 1):**
```
✅ PQ Status: "pq-missing"
✅ Message: "Classical cryptography only"
✅ Protected: false
```

**With Hybrid certificate (Option 2):**
```
✅ PQ Status: "pq-protected"
✅ Message: "Protected by ML-DSA-65"
✅ Protected: true
```

---

## ⚠️ Troubleshooting

### Problem: `Certificate files not found`

**Solution:** Generate certificate first (see Prerequisites above)

### Problem: `gBrowser is not defined`

**Solution:** Use **Browser Console** (Ctrl+Shift+J), not Web Console (F12)

### Problem: `secInfo is undefined`

**Solution:** Make sure you're on the https://localhost:8443 page first

### Problem: `Address already in use`

**Solution:** Kill existing server:
```bash
pkill -f test_pq_server
```

Then restart:
```bash
python3 test_pq_server.py
```

---

## 🎓 Recommendation

1. **Start with Option 1** (RSA certificate) to verify the API works
2. **Then do Option 2** (Hybrid certificate) for full end-to-end PQ testing

Both are valid tests! The API should work correctly with both certificate types.

---

## 📚 Additional Resources

- **Full setup guide:** `TESTING_WITH_HYBRID_CERTS.md`
- **Console help:** `SIMPLE_TEST_COMMAND.md`
- **Certificate analysis:** `CERTIFICATE_ANALYSIS.md`
- **Debugging:** `DEBUG_SECINFO.md`

---

## 🎉 Success Criteria

**You've succeeded if:**
- ✅ Server starts without errors
- ✅ Firefox loads https://localhost:8443
- ✅ Browser Console shows PQ status (either "pq-missing" or "pq-protected")
- ✅ No JavaScript errors in console

**Your PQ implementation is working!** 🚀

