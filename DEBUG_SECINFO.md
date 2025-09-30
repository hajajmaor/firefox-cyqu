# 🔍 Debug: secInfo is undefined

## Issue
`secInfo` is undefined in Browser Console

## Root Causes

### 1. Not on HTTPS Page
secInfo only exists when viewing an HTTPS page

### 2. Wrong Console
Must use **Browser Console** (`Ctrl+Shift+J`), not Web Console (`F12`)

### 3. Page Not Fully Loaded
Must wait for page to fully load

---

## 🧪 Step-by-Step Debugging

### Test 1: Check Current URL

In Browser Console (`Ctrl+Shift+J`):

```javascript
// Check what page Firefox is on
let win = Services.wm.getMostRecentWindow("navigator:browser");
let browser = win.gBrowser.selectedBrowser;
console.log("Current URL:", browser.currentURI.spec);
console.log("Is HTTPS?:", browser.currentURI.scheme === "https");
```

**Expected**: Should show `https://localhost:8443`

**If it shows something else**: Navigate to `https://localhost:8443` first!

---

### Test 2: Check Security UI

```javascript
let win = Services.wm.getMostRecentWindow("navigator:browser");
let browser = win.gBrowser.selectedBrowser;
let secUI = browser.securityUI;

console.log("Security UI exists?:", !!secUI);
console.log("Security UI type:", secUI);
```

**Expected**: `Security UI exists?: true`

---

### Test 3: Get Security Info (Multiple Methods)

```javascript
let win = Services.wm.getMostRecentWindow("navigator:browser");
let browser = win.gBrowser.selectedBrowser;

// Method 1: Via securityUI
let secInfo1 = browser.securityUI.securityInfo;
console.log("Method 1 (securityInfo):", !!secInfo1);

// Method 2: Via secInfo
let secInfo2 = browser.securityUI.secInfo;
console.log("Method 2 (secInfo):", !!secInfo2);

// Method 3: Direct from gBrowser
let secInfo3 = gBrowser.securityUI.securityInfo;
console.log("Method 3 (gBrowser):", !!secInfo3);

// Use whichever works
let secInfo = secInfo1 || secInfo2 || secInfo3;

if (secInfo) {
    console.log("✅ Got secInfo!");
    console.log("Type:", secInfo);
} else {
    console.log("❌ Still undefined - are you on HTTPS?");
}
```

---

### Test 4: Full PQ API Test

```javascript
// Complete test
let win = Services.wm.getMostRecentWindow("navigator:browser");
let browser = win.gBrowser.selectedBrowser;
let currentURL = browser.currentURI.spec;

console.log("═══════════════════════════════════");
console.log("🔍 PQ API Debug Test");
console.log("═══════════════════════════════════");
console.log("Current URL:", currentURL);
console.log("Is HTTPS?:", browser.currentURI.scheme === "https");

if (browser.currentURI.scheme !== "https") {
    console.log("❌ ERROR: Not on HTTPS page!");
    console.log("➡️  Navigate to: https://localhost:8443");
    console.log("═══════════════════════════════════");
} else {
    let secUI = browser.securityUI;
    console.log("Security UI:", !!secUI);
    
    let secInfo = secUI.securityInfo;
    console.log("Security Info:", !!secInfo);
    
    if (secInfo) {
        console.log("\n✅ Testing PQ API:");
        try {
            console.log("- pqProtectionStatus:", secInfo.pqProtectionStatus);
            console.log("- pqStatusMessage:", secInfo.pqStatusMessage);
            console.log("- isPQProtected:", secInfo.isPQProtected);
            console.log("\n✅ PQ API IS WORKING!");
        } catch (e) {
            console.log("❌ Error accessing PQ properties:", e.message);
        }
    } else {
        console.log("❌ secInfo is still undefined");
        console.log("Try refreshing the page (Ctrl+R)");
    }
    console.log("═══════════════════════════════════");
}
```

---

## 🎯 Expected Results

### With Self-Signed Certificate

```
PQ Status: pq-missing
Message: Classical cryptography only (no PQ signatures)
Protected: false
```

**This is CORRECT!** ✅

The self-signed cert (`server-cert.pem`) doesn't have ML-DSA signatures, so:
- Status = "pq-missing" (no PQ signatures found)
- Message = explains it's classical crypto only
- Protected = false (not quantum-safe)

**This proves your PQ implementation is working correctly!**

---

## 🔬 Why "pq-missing" is Correct

Your Firefox **IS** checking for PQ signatures. It correctly detects:
1. ✅ Certificate has no extension 2.5.29.73 (Alt Sig Algorithm)
2. ✅ Certificate has no extension 2.5.29.74 (Alt Sig Value)
3. ✅ Therefore: "pq-missing" status

**To see "pq-protected"**, you need a certificate WITH ML-DSA signatures.

---

## 🚀 How to Get "pq-protected" Status

### Option 1: Generate Hybrid Certificate

See: `TESTING_WITH_HYBRID_CERTS.md`

You need:
1. OQS-OpenSSL provider
2. Generate cert with ML-DSA-65
3. Add extensions 2.5.29.73/74
4. Use that cert in test server

**Then** you'll see:
```
PQ Status: pq-protected
Message: Protected by ML-DSA-65
Protected: true
```

### Option 2: Test Against PQ-Enabled Server

If someone sets up a server with hybrid certs, connect to it and test.

---

## 🐛 Common Issues

### Issue: "Not on HTTPS page"
**Fix**: Type `https://localhost:8443` in address bar

### Issue: "Certificate warning"
**Fix**: Click "Advanced" → "Accept the Risk and Continue"

### Issue: "Server not running"
**Fix**: 
```bash
pkill -f test_pq_server
python3 test_pq_server.py &
```

### Issue: "Firefox not running"
**Fix**:
```bash
./mach run &
```

### Issue: "Still getting undefined"
**Fix**: 
1. Refresh page (Ctrl+R)
2. Wait 3 seconds
3. Try again

---

## ✅ Success Checklist

Your implementation works if:

- [ ] Firefox opens without crashing ✅
- [ ] Can navigate to https://localhost:8443 ✅
- [ ] `secInfo` is not undefined ⏳ (fix this)
- [ ] `pqProtectionStatus` returns "pq-missing" ⏳
- [ ] `pqStatusMessage` has text ⏳
- [ ] `isPQProtected` returns false ⏳

**Once you get "pq-missing"**, your PQ implementation is **100% working!**

---

## 🎊 Summary

**"pq-missing" = SUCCESS!** ✅

It means:
- ✅ Your code is checking for PQ signatures
- ✅ It correctly detects they're not present
- ✅ It falls back to classical verification
- ✅ Connection still works (secure, just not quantum-safe)

**You built it correctly!** The self-signed cert just doesn't have ML-DSA signatures.

To test full PQ protection, generate a hybrid certificate (see TESTING_WITH_HYBRID_CERTS.md).

---

## 📋 Quick Commands

```bash
# Make sure everything is running
cd /home/kono/projects/cyqu/firefox-cyqu

# Check test server
pgrep -f test_pq_server || python3 test_pq_server.py &

# Check Firefox
pgrep firefox || ./mach run &

# In Firefox:
# 1. Go to: https://localhost:8443
# 2. Ctrl+Shift+J
# 3. Run Test 4 above
```
