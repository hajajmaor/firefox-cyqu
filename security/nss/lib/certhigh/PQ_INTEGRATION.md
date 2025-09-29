# PQ Hybrid Signature Verification Integration Guide

## Overview

The PQ hybrid signature verification is implemented in `certpqvfy.c`. It verifies alternative (post-quantum) signatures on certificates that carry both classical and PQ signatures.

## Integration Points

### 1. SSL/TLS Certificate Chain Validation

**File**: `security/nss/lib/ssl/ssl3con.c` or `security/nss/lib/ssl/sslauth.c`

**After** the classical certificate chain validation succeeds, call:

```c
/* Classical chain validation passed */
SECStatus classicalRv = CERT_VerifyCert(...);
if (classicalRv != SECSuccess) {
    /* Fail - classical sig is authoritative */
    return classicalRv;
}

/* Now check PQ signatures (informational only) */
PRBool isPQProtected = PR_FALSE;
const char *pqStatus = CERT_GetPQVerificationStatus(certChain, &isPQProtected);

/* Store result for UI display */
ss->sec.pqProtected = isPQProtected;
ss->sec.pqStatusMessage = pqStatus;

/* Continue - connection succeeds regardless of PQ result */
return SECSuccess;
```

### 2. Certificate Viewer / Security Info

**File**: `browser/base/content/browser-siteIdentity.js` or similar

Access the PQ status from the SSL socket info:

```javascript
let pqProtected = securityInfo.isPQProtected;
let pqStatus = securityInfo.pqStatusMessage;

if (pqProtected) {
    // Show "PQ" badge
    document.getElementById("pq-badge").style.display = "block";
} else {
    // Show "Not PQ" in details
    document.getElementById("pq-status").textContent = pqStatus;
}
```

### 3. DevTools Security Panel

**File**: `devtools/client/netmonitor/src/components/SecurityPanel.js` or similar

Display PQ information:

```javascript
{
    label: "Post-Quantum Protection:",
    value: pqProtected ? "✓ ML-DSA verified" : pqStatus
}
```

## API Usage

### CERT_VerifyAltSignature()

Verify alternative signature on a single certificate:

```c
SECStatus rv = CERT_VerifyAltSignature(cert, issuerCert);
if (rv == SECSuccess) {
    /* Alt-sig is valid */
} else {
    /* Alt-sig missing, invalid, or unsupported algorithm */
}
```

### CERT_VerifyAltSignatureChain()

Verify entire chain (all-or-nothing):

```c
SECStatus rv = CERT_VerifyAltSignatureChain(certList);
if (rv == SECSuccess) {
    /* All certs have valid ML-DSA alt-sigs */
} else {
    /* One or more certs missing alt-sig or verification failed */
}
```

### CERT_GetPQVerificationStatus()

Get human-readable status:

```c
PRBool isPQProtected = PR_FALSE;
const char *msg = CERT_GetPQVerificationStatus(certList, &isPQProtected);

if (isPQProtected) {
    printf("✓ PQ Protected\n");
} else {
    printf("⚠ %s\n", msg);
}
```

## Error Handling

PQ verification errors are **non-fatal**:
- Connection succeeds based on classical signature only
- PQ failure is informational (shown in UI)
- User can see "Not PQ: <reason>" but connection proceeds

## Testing Certificates

To test, you need certificates with:
1. Classical signature (RSA-PSS or ECDSA) in standard fields
2. Extension 2.5.29.73 containing ML-DSA AlgorithmIdentifier
3. Extension 2.5.29.74 containing ML-DSA signature BIT STRING
4. ML-DSA public key in issuer certificate

Use EJBCA or OpenSSL with PQC support to generate test chains.

## Build Configuration

Ensure liboqs is linked:
- See `security/nss/lib/freebl/BUILD_NOTES.md`
- freebl must link against liboqs for ML-DSA verification
- Add `certpqvfy.c` to certhigh build target

## Preferences

Add to `modules/libpref/init/all.js`:

```javascript
pref("security.pq.prefer_alt_sig", true);
pref("security.pq.require_alt_sig", false);  // false = don't fail connection
pref("security.pq.show_ui_indicator", true);
```
