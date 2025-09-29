# 🎯 PQ Hybrid Signatures - Progress Tracker

**Project**: Firefox NSS ML-DSA-65 (Dilithium-3) Hybrid Signature Support  
**Started**: 2025-09-29  
**Status**: Planning

---

## 📊 Overall Progress: 0/11 Steps Complete

### ✅ = Done | 🚧 = In Progress | ⏸️ = Blocked | ⏭️ = Pending

---

## Step 1: NSS Baseline Build ⏭️
- [ ] Build NSS standalone (`./build.sh -o`)
- [ ] Verify artifacts in `dist/`
- [ ] Commit: `chore(nss): confirm vanilla build`

**Status**: Not started  
**Notes**: 

---

## Step 2: Vendor liboqs ⏭️
- [ ] Add liboqs as git submodule
- [ ] Verify submodule is tracked
- [ ] Commit: `build(liboqs): add submodule for PQ verify`

**Status**: Not started  
**Notes**: 

---

## Step 3: freebl wrapper ⏭️
- [ ] Create `security/nss/lib/freebl/oqs_dilithium.c`
- [ ] Create `security/nss/lib/freebl/oqs_dilithium.h`
- [ ] Update freebl build files (link liboqs)
- [ ] Verify compilation
- [ ] Commit: `feat(freebl): ML-DSA-65 verify via liboqs (verify-only)`

**Status**: Not started  
**Notes**: 

---

## Step 4: Register OIDs ⏭️
- [ ] Add ML-DSA-65 OID to `secoid.c`
- [ ] Add ML-DSA-65 OID to `secoidt.h`
- [ ] Add extension 2.5.29.73 (Alt Sig Algorithm)
- [ ] Add extension 2.5.29.74 (Alt Sig Value)
- [ ] Verify OID registration
- [ ] Commit: `feat(oids): add ML-DSA-65 + names for 2.5.29.73/74`

**Status**: Not started  
**Notes**: 

---

## Step 5: Parse alt-sig into CERTCertificate ⏭️
- [ ] Locate X.509 decode path
- [ ] Parse extension 2.5.29.73 → AlgorithmIdentifier
- [ ] Parse extension 2.5.29.74 → BIT STRING
- [ ] Add `alt_sig_oid` field to CERTCertificate
- [ ] Add `alt_sig_value` field to CERTCertificate
- [ ] Verify parsing with test cert
- [ ] Commit: `feat(x509): decode Alternative Signature Algorithm/Value (73/74)`

**Status**: Not started  
**Notes**: 

---

## Step 6: Chain Validation (Hybrid Verify) ⏭️
- [ ] Locate chain verification code
- [ ] Add hook after classical signature verification
- [ ] Implement hybrid verification logic:
  - [ ] Verify classical signature (existing)
  - [ ] Check for alt-sig extensions (73/74)
  - [ ] Call `oqs_dilithium_verify` if present
  - [ ] Record PQ result per cert
- [ ] Implement global chain policy:
  - [ ] Mark **PQ** only if ALL certs have alt-sig AND verify
  - [ ] Mark **Not PQ** if any cert missing alt-sig OR fails verify
- [ ] Ensure connection succeeds even if PQ fails
- [ ] Commit: `feat(verify): hybrid path verification; prefer PQ, fall back classical`

**Status**: Not started  
**Notes**: 

---

## Step 7: Prefs (about:config) ⏭️
- [ ] Add pref `security.pq.prefer_alt_sig` (default: true)
- [ ] Add pref `security.pq.require_alt_sig` (default: false)
- [ ] Wire prefs to verification logic
- [ ] Test pref changes
- [ ] Commit: `feat(prefs): default to prefer alt-sig; do not require`

**Status**: Not started  
**Notes**: 

---

## Step 8: UI - PQ Indicator ⏭️
- [ ] Add "PQ" badge to lock icon (when all checks pass)
- [ ] Show "Not PQ" in identity popup (when checks fail)
- [ ] Update DevTools Security panel:
  - [ ] Show "Hybrid (RSA-PSS + ML-DSA-65)" when alt-sig present
  - [ ] Show "PQ validation: Passed" or "Not PQ: <reason>"
- [ ] Locate site identity panel code
- [ ] Locate security viewer code
- [ ] Wire NSS verdict to UI
- [ ] Commit: `feat(ui): show PQ badge on success; show 'Not PQ' otherwise`

**Status**: Not started  
**Notes**: 

---

## Step 9: Unit Tests ⏭️
- [ ] Add freebl ML-DSA-65 KAT tests (positive cases)
- [ ] Add freebl ML-DSA-65 KAT tests (negative cases)
- [ ] Add x509 parser tests for extensions 73/74
- [ ] Verify OID matching (ML-DSA-65)
- [ ] Run all tests
- [ ] Commit: `test: add ML-DSA-65 KATs + alt-sig parse tests`

**Status**: Not started  
**Notes**: 

---

## Step 10: Integration Tests ⏭️
- [ ] Create test fixture: Good chain (Root/Sub/Leaf with 73/74)
- [ ] Create test fixture: Missing alt-sig at Sub
- [ ] Create test fixture: Bad alt-sig on Leaf
- [ ] Write integration test: Good chain → **PQ** badge
- [ ] Write integration test: Missing alt → **Not PQ (missing at Sub)**
- [ ] Write integration test: Bad alt → **Not PQ (verify failed)**, connection OK
- [ ] Run all integration tests
- [ ] Commit: `test(integration): hybrid chain, missing-alt, and bad-alt cases`

**Status**: Not started  
**Notes**: 

---

## Step 11: Build & Run ⏭️
- [ ] Build NSS with liboqs: `cd security/nss && ./build.sh -o`
- [ ] Build Firefox: `./mach build`
- [ ] Run Firefox: `./mach run`
- [ ] Verify linking (freebl → liboqs)
- [ ] Manual smoke test with test certificates
- [ ] Commit: `docs(build): how to build Firefox with liboqs-backed PQ verify`

**Status**: Not started  
**Notes**: 

---

## 🎓 Acceptance Criteria

- [ ] NSS recognizes **2.5.29.73/74** and exposes them in cert viewer
- [ ] Dil-3 (ML-DSA-65) verify runs via **liboqs** and returns true for good chain
- [ ] **UI shows "PQ"** only if **every** chain element has alt-sig **and passes** Dil-3 verify
- [ ] **UI shows "Not PQ"** if any cert missing alt-sig or verification fails
- [ ] Connection doesn't fail when PQ fails (`require_alt_sig=false`)
- [ ] Docs refer to **FIPS-204** and **LAMPS ML-DSA** for identifiers

---

## 📝 Quick Commands

```bash
# Build NSS
cd security/nss && ./build.sh -o

# Build Firefox
./mach build

# Run Firefox
./mach run

# Run tests
./mach test security/nss/tests/
```

---

**Last Updated**: 2025-09-29
