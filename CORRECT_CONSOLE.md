# ⚠️ IMPORTANT: Use the Correct Console!

## 🐛 **Common Error: "gBrowser is not defined"**

**Problem**: You're using the wrong console!

### ❌ **Wrong**: Web Console (F12)
- Opens with `F12` or `Ctrl+Shift+K`
- Shows website-level JavaScript
- **Cannot access** `gBrowser` (browser internals)
- For debugging web pages only

### ✅ **Correct**: Browser Console (Ctrl+Shift+J)
- Opens with `Ctrl+Shift+J` or `Cmd+Shift+J` (Mac)
- Shows browser-level JavaScript
- **Can access** `gBrowser`, `Services`, etc.
- For debugging Firefox itself

---

## 🎯 **How to Fix**

### Step 1: Close Web Console (if open)

Press `F12` to close it.

### Step 2: Open Browser Console

Press: **`Ctrl+Shift+J`** (Linux/Windows) or **`Cmd+Shift+J`** (Mac)

You'll see a different console with messages from Firefox itself.

### Step 3: Test

Run this to verify:

```javascript
console.log(typeof gBrowser);
```

**Expected output**: `"object"` ✅

**If you get `"undefined"`**: You're still in the wrong console!

---

## 🧪 **Correct Test Commands**

Once in **Browser Console** (Ctrl+Shift+J):

### Quick Test
```javascript
let secInfo = gBrowser.securityUI.securityInfo;
console.log("PQ Status:", secInfo.pqProtectionStatus);
```

### Full Test
```javascript
// Get security info
let secInfo = gBrowser.securityUI.securityInfo;

// Check PQ attributes exist
console.log("Has pqProtectionStatus:", typeof secInfo.pqProtectionStatus);
console.log("Has pqStatusMessage:", typeof secInfo.pqStatusMessage);
console.log("Has isPQProtected:", typeof secInfo.isPQProtected);

// Read values
console.log("\n=== PQ Protection Status ===");
console.log("Status:", secInfo.pqProtectionStatus);
console.log("Message:", secInfo.pqStatusMessage);
console.log("Protected:", secInfo.isPQProtected);

// Check preferences
console.log("\n=== PQ Preferences ===");
console.log("prefer_alt_sig:", 
  Services.prefs.getBoolPref("security.pq.prefer_alt_sig"));
console.log("require_alt_sig:", 
  Services.prefs.getBoolPref("security.pq.require_alt_sig"));
console.log("show_ui_indicator:", 
  Services.prefs.getBoolPref("security.pq.show_ui_indicator"));
```

---

## 📊 **What You'll See**

### On https://localhost:8443 (test server)

**Browser Console** (Ctrl+Shift+J):
```
PQ Status: pq-missing
Message: Classical cryptography only (no PQ signatures)
Protected: false
```

**Web Console** (F12):
```
❌ Error: gBrowser is not defined
```

### On any HTTPS site

**Browser Console** (Ctrl+Shift+J):
```
PQ Status: pq-missing
Message: Classical cryptography only (no PQ signatures)
Protected: false
```

(Most sites don't have PQ signatures yet)

---

## 🎓 **Remember**

| Console | Keyboard | Access Level | Use For |
|---------|----------|--------------|---------|
| **Browser Console** | `Ctrl+Shift+J` | Browser internals | Testing PQ API ✅ |
| **Web Console** | `F12` | Website only | Debugging sites ❌ |

---

## 🚀 **Quick Reference**

**Open Browser Console**: `Ctrl+Shift+J`

**Test Command**:
```javascript
let secInfo = gBrowser.securityUI.securityInfo;
console.log("PQ:", secInfo.pqProtectionStatus);
```

**Expected**: `"pq-missing"` (for normal certs) ✅

---

**Now try again with the correct console!** 🎉
