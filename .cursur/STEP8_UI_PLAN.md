# Step 8: PQ UI Indicator Implementation Plan

## 🎯 Goal
Add visual indicators to show when a connection uses Post-Quantum cryptography.

## 📍 UI Locations

### 1. Site Identity Panel (Lock Icon Popup)
**File**: `browser/base/content/browser-siteIdentity.js`  
**Location**: Click the lock icon left of URL bar  
**What to add**:
- "PQ Protected" badge when all certs have valid ML-DSA signatures
- "Not PQ" with reason when PQ verification fails or missing
- Connection still works either way (informational only)

### 2. DevTools Security Panel
**File**: `devtools/client/netmonitor/src/components/SecurityPanel.js`  
**Location**: DevTools → Network tab → Select request → Security tab  
**What to add**:
- "Post-Quantum Protection:" row
- Value: "✓ ML-DSA-65" or "Not PQ: [reason]"
- Show per-certificate PQ status for full chain

### 3. Certificate Viewer (Enhanced)
**File**: `security/manager/pki/resources/content/certViewer.xhtml`  
**Location**: Page Info → Security → View Certificate  
**What to add**:
- Show alternative signature extensions (2.5.29.73, 2.5.29.74)
- Display ML-DSA algorithm details
- Show PQ verification result

## 🔧 Implementation Approach

### Phase A: C++ Backend API
Create API to expose PQ status to frontend:

**File**: `security/manager/ssl/nsISSLStatus.idl`

```idl
interface nsISSLStatus : nsISupports {
  // ... existing methods ...
  
  /**
   * Post-Quantum protection status for this connection
   * Returns one of:
   *   "pq-protected"     - All certs have valid ML-DSA signatures
   *   "pq-missing"       - Some/all certs lack PQ signatures
   *   "pq-verify-failed" - PQ signature verification failed
   *   "pq-disabled"      - PQ verification disabled in prefs
   */
  readonly attribute ACString pqProtectionStatus;
  
  /**
   * Human-readable description of PQ status
   * e.g. "Protected by ML-DSA-65" or "Not PQ: missing at Intermediate CA"
   */
  readonly attribute ACString pqStatusMessage;
  
  /**
   * True if connection is quantum-safe
   */
  readonly attribute boolean isPQProtected;
}
```

**Implementation**: `security/manager/ssl/SSLStatus.cpp`

```cpp
NS_IMETHODIMP
SSLStatus::GetPqProtectionStatus(nsACString& aStatus) {
  if (!mServerCert) {
    aStatus.AssignLiteral("pq-unknown");
    return NS_OK;
  }
  
  // Get certificate chain
  nsTArray<RefPtr<nsIX509Cert>> certList;
  mServerCert->GetChain(certList);
  
  // Call NSS PQ verification
  PRBool isPQ = PR_FALSE;
  const char* statusStr = CERT_GetPQVerificationStatus(
    /* convert certList to CERTCertList */,
    &isPQ
  );
  
  if (isPQ) {
    aStatus.AssignLiteral("pq-protected");
  } else if (strstr(statusStr, "missing")) {
    aStatus.AssignLiteral("pq-missing");
  } else if (strstr(statusStr, "failed")) {
    aStatus.AssignLiteral("pq-verify-failed");
  } else {
    aStatus.AssignLiteral("pq-disabled");
  }
  
  return NS_OK;
}

NS_IMETHODIMP
SSLStatus::GetIsPQProtected(bool* aIsPQProtected) {
  nsAutoCString status;
  GetPqProtectionStatus(status);
  *aIsPQProtected = status.EqualsLiteral("pq-protected");
  return NS_OK;
}
```

### Phase B: JavaScript Frontend

**File**: `browser/base/content/browser-siteIdentity.js`

```javascript
updatePQStatus() {
  let pqBox = document.getElementById("identity-popup-pq-status");
  if (!pqBox) return;
  
  let securityInfo = gBrowser.securityUI.securityInfo;
  if (!securityInfo) {
    pqBox.hidden = true;
    return;
  }
  
  let isPQProtected = securityInfo.isPQProtected;
  let statusMsg = securityInfo.pqStatusMessage;
  
  if (isPQProtected) {
    pqBox.setAttribute("type", "protected");
    pqBox.textContent = "🔒 Quantum-Safe (ML-DSA)";
  } else {
    pqBox.setAttribute("type", "not-protected");
    pqBox.textContent = statusMsg; // e.g. "Not PQ: missing"
  }
  
  pqBox.hidden = false;
}

// Call from updateSecurityInfo()
updateSecurityInfo() {
  // ... existing code ...
  this.updatePQStatus();
}
```

### Phase C: XUL/HTML Markup

**File**: `browser/base/content/browser-siteIdentity.inc.xhtml`

```xml
<!-- Add after security-warning section -->
<hbox id="identity-popup-pq-status-box"
      class="identity-popup-security-content">
  <image class="identity-popup-pq-icon"/>
  <vbox flex="1">
    <label id="identity-popup-pq-label"
           class="identity-popup-headline"
           value="&identity.pqProtection.label;"/>
    <description id="identity-popup-pq-status"
                 class="identity-popup-security-state-label"/>
  </vbox>
</hbox>
```

**File**: `browser/locales/en-US/browser/browser.ftl`

```ftl
## Post-Quantum Protection

identity-pq-protection-label = Quantum Protection:
identity-pq-protected = Protected by ML-DSA post-quantum signatures
identity-pq-not-protected = Classical cryptography only
identity-pq-missing = No post-quantum signatures present
identity-pq-verify-failed = Post-quantum signature verification failed
```

### Phase D: CSS Styling

**File**: `browser/themes/shared/identity-block/identity-block.css`

```css
/* PQ Protection Status */
#identity-popup-pq-status-box {
  margin-top: 10px;
  padding: 8px 12px;
  border-radius: 4px;
  background-color: var(--panel-separator-color);
}

#identity-popup-pq-status[type="protected"] {
  color: var(--green-60);
  font-weight: 600;
}

#identity-popup-pq-status[type="not-protected"] {
  color: var(--text-color-deemphasized);
  font-style: italic;
}

.identity-popup-pq-icon {
  width: 24px;
  height: 24px;
  margin-inline-end: 8px;
  list-style-image: url("chrome://browser/skin/quantum-shield.svg");
}
```

## 🎨 Visual Design

### Site Identity Panel - PQ Protected
```
┌─────────────────────────────────────────────┐
│  🔒 Connection is secure                    │
│                                             │
│  Certificate: Let's Encrypt                 │
│  Valid until: Dec 31, 2025                  │
│                                             │
│  🛡️ Quantum Protection:                     │
│  🔒 Quantum-Safe (ML-DSA-65)                │
│                                             │
│  [More Information]                         │
└─────────────────────────────────────────────┘
```

### Site Identity Panel - Not PQ
```
┌─────────────────────────────────────────────┐
│  🔒 Connection is secure                    │
│                                             │
│  Certificate: DigiCert                      │
│  Valid until: Jan 15, 2026                  │
│                                             │
│  🛡️ Quantum Protection:                     │
│  Classical cryptography only                │
│                                             │
│  [More Information]                         │
└─────────────────────────────────────────────┘
```

## 📋 Implementation Checklist

- [ ] Add `pqProtectionStatus`, `pqStatusMessage`, `isPQProtected` to `nsISSLStatus.idl`
- [ ] Implement getters in `SSLStatus.cpp`
- [ ] Wire up NSS `CERT_GetPQVerificationStatus()` call
- [ ] Add UI elements to `browser-siteIdentity.inc.xhtml`
- [ ] Implement `updatePQStatus()` in `browser-siteIdentity.js`
- [ ] Add localization strings to `browser.ftl`
- [ ] Add CSS styling
- [ ] Create quantum-shield.svg icon
- [ ] Test with PQ and non-PQ certificates
- [ ] Add DevTools Security panel integration

## 🧪 Testing Strategy

### Test Cases
1. **PQ Certificate**: All certs in chain have valid ML-DSA sigs → Show "Quantum-Safe"
2. **No PQ**: Standard HTTPS site → Show "Classical cryptography only"
3. **Mixed Chain**: Root has PQ, intermediate missing → Show "Not PQ: missing"
4. **Bad Signature**: PQ sig present but invalid → Show "verification failed"
5. **Preference Disabled**: `security.pq.prefer_alt_sig = false` → Show "disabled"

### Manual Testing
```bash
# 1. Generate test certificate with PQ signatures (EJBCA)
# 2. Install test CA in Firefox
# 3. Visit test site
# 4. Click lock icon → verify PQ status shows
# 5. Open DevTools Security tab → verify details shown
```

## 📦 Files to Create/Modify

**Backend (C++/IDL)**:
- `security/manager/ssl/nsISSLStatus.idl` - Add PQ status API
- `security/manager/ssl/SSLStatus.h` - Declare new methods
- `security/manager/ssl/SSLStatus.cpp` - Implement PQ status logic

**Frontend (JS)**:
- `browser/base/content/browser-siteIdentity.js` - Add `updatePQStatus()`
- `devtools/client/netmonitor/src/components/SecurityPanel.js` - Add PQ row

**UI (XUL/HTML/CSS)**:
- `browser/base/content/browser-siteIdentity.inc.xhtml` - Add PQ status box
- `browser/themes/shared/identity-block/identity-block.css` - PQ styling
- `browser/themes/shared/icons/quantum-shield.svg` - PQ icon (create)

**Localization**:
- `browser/locales/en-US/browser/browser.ftl` - PQ status strings

**Total**: ~12 files, ~400 lines of code

## ⏱️ Estimated Time

- **Phase A (Backend API)**: 2 hours
- **Phase B (Frontend JS)**: 1 hour
- **Phase C (UI Markup)**: 1 hour
- **Phase D (CSS/Icons)**: 1 hour
- **Testing**: 1 hour
- **Total**: ~6 hours

## 🎯 Success Criteria

- [ ] Lock icon popup shows PQ status
- [ ] Status updates correctly for PQ vs non-PQ sites
- [ ] Visual distinction between protected/not-protected
- [ ] DevTools shows per-certificate PQ details
- [ ] Localization works
- [ ] UI matches Firefox design guidelines
- [ ] No performance impact on page loads

---

**Status**: Ready to implement  
**Dependencies**: None (works with stubbed ML-DSA functions)  
**Next**: Start with Phase A (Backend API)
