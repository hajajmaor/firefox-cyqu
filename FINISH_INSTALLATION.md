# 🏁 FINAL STEPS: Complete PQ Installation

## ✅ **What's Done**
- ✅ All code implemented (100%)
- ✅ ml_dsa.c uncommented (real verification)
- ✅ Backend API complete
- ✅ JavaScript integration done
- ✅ Test server ready
- ✅ Documentation complete

## 🔨 **What's Left: 2 Steps**

---

## **Step 1: Install liboqs** (5 minutes)

### Option A: Automated Script (Recommended)

```bash
cd /home/kono/projects/cyqu/firefox-cyqu
sudo ./install_liboqs.sh
```

This will:
1. Configure liboqs with cmake
2. Build ML-DSA support
3. Install to /usr/local
4. Update library cache

### Option B: Manual Installation

```bash
cd /home/kono/projects/cyqu/firefox-cyqu/security/third_party/liboqs
mkdir -p build && cd build

# Configure
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DOQS_BUILD_ONLY_LIB=ON \
      ..

# Build
make -j$(nproc)

# Install
sudo make install
sudo ldconfig
```

### Verify Installation

```bash
# Check library is installed
ldconfig -p | grep liboqs

# Check headers exist
ls /usr/local/include/oqs/

# Should see:
# liboqs.so.5 -> /usr/local/lib/liboqs.so.5
# oqs.h, sig.h, etc.
```

---

## **Step 2: Rebuild Firefox** (15-30 minutes)

```bash
cd /home/kono/projects/cyqu/firefox-cyqu

# Clean build (recommended to pick up new libraries)
./mach clobber

# Build with liboqs
./mach build 2>&1 | tee /tmp/firefox-pq-final.log

# Run
./mach run
```

### Build Success Indicators

Look for:
```
✅ Building freebl/ml_dsa.c
✅ Linking liboqs
✅ Build completed successfully
```

### If Build Fails

**Error**: `oqs/oqs.h not found`

**Fix**:
```bash
# Add include path to moz.build
echo 'CFLAGS += ["-I/usr/local/include"]' >> security/nss/lib/freebl/moz.build
echo 'LDFLAGS += ["-L/usr/local/lib", "-loqs"]' >> security/nss/lib/freebl/moz.build
./mach build
```

**Error**: `undefined reference to OQS_SIG_new`

**Fix**:
```bash
# Check liboqs is in linker path
sudo ldconfig
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
./mach build
```

---

## 🧪 **Step 3: Test Everything** (5 minutes)

### Terminal 1: Start Test Server

```bash
python3 test_pq_server.py
```

### Terminal 2: Run Firefox

```bash
./mach run
```

### In Firefox: Test Console

**Open Browser Console**: `Ctrl+Shift+J` (NOT F12!)

```javascript
let secInfo = gBrowser.securityUI.securityInfo;
console.log("Status:", secInfo.pqProtectionStatus);
console.log("Message:", secInfo.pqStatusMessage);
console.log("Protected:", secInfo.isPQProtected);
```

**Expected** (with self-signed cert):
```
Status: pq-missing
Message: Classical cryptography only (no PQ signatures)
Protected: false
```

✅ **This is correct!** The API works, just no PQ sigs in cert yet.

---

## 🔬 **Step 4: Test with Hybrid Certificates** (Optional, 30 min)

See: `TESTING_WITH_HYBRID_CERTS.md`

Generate real ML-DSA certificates:

```bash
# Install OQS-OpenSSL provider
git clone https://github.com/open-quantum-safe/oqs-provider.git /tmp/oqs-provider
cd /tmp/oqs-provider
cmake -S . -B _build && cmake --build _build && sudo cmake --install _build

# Generate hybrid certificate
openssl genpkey -algorithm mldsa65 -provider oqsprovider -out hybrid-key.pem
openssl req -new -x509 -key hybrid-key.pem -provider oqsprovider \
  -out hybrid-cert.pem -days 365 -subj "/CN=localhost"

# Use with test server
python3 test_pq_server.py
# (Update server to use hybrid-cert.pem)
```

**Then you'll see**:
```javascript
Status: pq-protected
Message: Protected by ML-DSA-65
Protected: true
```

🎉 **Full PQ protection!**

---

## 📊 **Final Checklist**

- [ ] liboqs installed (`ldconfig -p | grep liboqs` works)
- [ ] Firefox builds without errors
- [ ] Can run `./mach run`
- [ ] Test server starts
- [ ] Can connect to https://localhost:8443
- [ ] Browser Console (Ctrl+Shift+J) shows PQ API working
- [ ] `secInfo.pqProtectionStatus` returns a string
- [ ] Preferences exist in `about:config`

**All checked?** 🎊 **YOU'RE DONE!**

---

## 🎯 **Expected Timeline**

| Task | Time | Status |
|------|------|--------|
| Install liboqs | 5 min | ⏳ |
| Build Firefox | 20 min | ⏳ |
| Test basic API | 2 min | ⏳ |
| (Optional) Hybrid certs | 30 min | Optional |
| **TOTAL** | **27 min** | |

---

## 🐛 **Troubleshooting Guide**

### gBrowser is not defined
- **Fix**: Use `Ctrl+Shift+J` (Browser Console), not `F12` (Web Console)
- See: `CORRECT_CONSOLE.md`

### oqs/oqs.h not found
- **Fix**: Install liboqs with `./install_liboqs.sh`
- Verify: `ls /usr/local/include/oqs/`

### undefined reference to OQS_SIG_new
- **Fix**: Run `sudo ldconfig`
- Check: `ldconfig -p | grep liboqs`

### Can't connect to test server
- **Fix**: Import certificate in Firefox
- Settings → Certificates → Import `server-cert.pem`

### secInfo is null
- **Fix**: Visit an HTTPS page first
- Try: https://localhost:8443

---

## 🚀 **Commands Summary**

```bash
# 1. Install liboqs
sudo ./install_liboqs.sh

# 2. Build Firefox
./mach clobber && ./mach build

# 3. Test
# Terminal 1:
python3 test_pq_server.py

# Terminal 2:
./mach run
# Then: Ctrl+Shift+J → run console tests
```

---

## 📚 **Documentation**

- `CORRECT_CONSOLE.md` - Fix gBrowser error
- `TEST_NOW.md` - Quick testing guide
- `TESTING_WITH_HYBRID_CERTS.md` - Advanced hybrid cert testing
- `TEST_PQ_API.md` - Complete API test suite
- `PROJECT_COMPLETED.md` - Full project report

---

## 🏆 **SUCCESS CRITERIA**

When everything works, you'll see:

### ✅ Basic Test (Self-signed cert)
```javascript
Status: "pq-missing"
Message: "Classical cryptography only"
Protected: false
```

### ✅ Full Test (Hybrid cert)
```javascript
Status: "pq-protected"
Message: "Protected by ML-DSA-65"
Protected: true
```

---

## 🎉 **YOU'RE ALMOST THERE!**

Just run:
```bash
sudo ./install_liboqs.sh
./mach build
```

**Then test and celebrate!** 🚀🔐✨
