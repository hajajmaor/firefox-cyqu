# 📔 Implementation Notes & Decisions

**Project**: Firefox NSS ML-DSA-65 Hybrid Signatures  
**Started**: 2025-09-29

---

## 🗓️ Journal

### 2025-09-29 - Project Setup
- Created progress tracker and notes file
- Reviewed task requirements
- Ready to begin implementation

---

## 🎯 Key Design Decisions

### Verification Strategy
- **Classical signature is authoritative**: Connection succeeds/fails based on classical sig only
- **PQ signature is informational**: Used only for UI badge/indicator
- **Prefer PQ**: If both present and valid, show "PQ" badge
- **Graceful degradation**: Missing or invalid PQ → show "Not PQ" but connection proceeds

### Chain Policy
- **All-or-nothing PQ indicator**: 
  - "PQ" badge ONLY if every cert in chain has alt-sig extensions AND all verify successfully
  - Any missing alt-sig OR any verification failure → "Not PQ"
- **Rationale**: Security is only as strong as weakest link in chain

### Prefs
- `security.pq.prefer_alt_sig` = true (default)
- `security.pq.require_alt_sig` = false (default)
- Future: could set `require_alt_sig=true` to fail connections without valid PQ sigs

---

## 🔍 Key Files & Locations

### NSS Core
- OID tables: `security/nss/lib/util/secoid.c`, `secoidt.h`
- freebl: `security/nss/lib/freebl/`
- X.509 parsing: (TBD - need to locate)
- Chain verification: (TBD - need to locate)

### liboqs
- Location: `security/third_party/liboqs`
- API: Dilithium verify functions

### Firefox UI
- Site identity panel: (TBD)
- DevTools Security panel: (TBD)
- Lock icon/badge: (TBD)

---

## 🐛 Issues & Blockers

### Current Blockers
- None

### Resolved Issues
- None yet

---

## ⚠️ Gotchas & Watch-outs

### ML-DSA vs Dilithium
- **Dilithium** is the original CRYSTALS-Dilithium algorithm
- **ML-DSA** (Module-Lattice-Based Digital Signature Algorithm) is the FIPS-204 standardized version
- We're implementing **ML-DSA-65** (equivalent to Dilithium3)
- OID references should use FIPS-204 identifiers

### OID Values
- ML-DSA-65: (TBD - need to look up exact OID from FIPS-204/LAMPS)
- Extension 2.5.29.73: Alternative Signature Algorithm
- Extension 2.5.29.74: Alternative Signature Value

### TBS (To-Be-Signed) Bytes
- For alt-sig verification, we need the **exact TBS bytes** from the certificate
- NSS likely already has this as `cert->tbsDer` or similar
- Critical: same TBS bytes used for both classical and PQ signatures

### Build System
- Need to link freebl against liboqs
- May need to update `moz.build` or NSS build scripts
- Watch for linking order and dependencies

---

## 📚 Reference Links

- [FIPS-204 ML-DSA](https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.204.pdf)
- [LAMPS ML-DSA in PKIX](https://datatracker.ietf.org/doc/draft-ietf-lamps-dilithium-certificates/)
- [EJBCA Hybrid Signatures](https://docs.keyfactor.com/ejbca/9.0/tutorial-create-pqc-hybrid-ca-chain)
- [liboqs GitHub](https://github.com/open-quantum-safe/liboqs)
- [NSS Structure](https://firefox-source-docs.mozilla.org/security/nss/legacy_extracts/structure.html)

---

## 💡 Ideas & Future Work

- Consider supporting other PQ algorithms (ML-DSA-44, ML-DSA-87, Falcon, etc.)
- Add telemetry to measure PQ cert adoption
- Performance profiling of PQ verification
- Support for composite signatures (single signature combining classical + PQ)
- Browser extension to test PQ certs

---

**Last Updated**: 2025-09-29
