# 🧱 NSS baseline build

**Step 1 — Build NSS standalone**

```bash
cd security/nss
./build.sh -o
```

(Verifies local toolchain; artifacts land under `dist/`.) ([firefox-source-docs.mozilla.org][1])
**Commit**: `chore(nss): confirm vanilla build`

---

# 🧩 Add liboqs (verify-only)

**Step 2 — Vendor liboqs**

```bash
cd ../..
git submodule add https://github.com/open-quantum-safe/liboqs security/third_party/liboqs
git add security/third_party/liboqs
```

(We’ll link verify-only from freebl.) ([GitHub][2])
**Commit**: `build(liboqs): add submodule for PQ verify`

**Step 3 — freebl wrapper**
Create:

* `security/nss/lib/freebl/oqs_dilithium.c` (calls liboqs verify for ML-DSA-65)
* `security/nss/lib/freebl/oqs_dilithium.h`
* Update freebl build files to compile/link the wrapper.

**Commit**: `feat(freebl): ML-DSA-65 verify via liboqs (verify-only)`

---

# 🆔 OIDs & alt-sig extensions

**Step 4 — Register OIDs**

* Add ML-DSA-65 (Dilithium-3) algorithm identifier to NSS OID tables (`secoid.c`, `secoidt.h`) with readable names/tags. ([Chromium Git Repositories][3])
* Recognize X.509v3 extensions:

  * **2.5.29.73** Alternative Signature **Algorithm**
  * **2.5.29.74** Alternative Signature **Value**
    (These are the EJBCA “Hybrid/Alternative” extensions.) ([docs.keyfactor.com][4])

**Commit**: `feat(oids): add ML-DSA-65 + names for 2.5.29.73/74`

**Step 5 — Parse alt-sig into CERTCertificate**

* In the X.509 decode path, parse:

  * 2.5.29.73 → inner `AlgorithmIdentifier` OID (**must match ML-DSA-65**)
  * 2.5.29.74 → BIT STRING (alt signature bytes)
* Add optional fields on `CERTCertificate` to hold `alt_sig_oid` and `alt_sig_value`.

**Commit**: `feat(x509): decode Alternative Signature Algorithm/Value (73/74)`

Refs for ML-DSA identifiers & usage in PKIX: **FIPS-204** + LAMPS draft. ([NIST Publications][5])

---

# ✅ Chain validation (always prefer PQ)

**Step 6 — Hybrid verify hook**
Hook after classical signature verification of each chain element:

Pseudocode:

```c
bool classical_ok = VerifyClassical(cert);
if (!classical_ok) return FAIL;

bool have_alt = has_ext_73_74(cert) && alt_oid == OID_ML_DSA_65;
bool pq_ok = false;
if (have_alt) {
  const SECItem *tbs = cert->tbsDer; // existing TBS bytes
  pq_ok = oqs_dilithium_verify(alt_pubkey_from_issuer, tbs, alt_sig);
}
record_pq_result(cert, have_alt, pq_ok);
return SUCCESS; // classical governs connection outcome
```

Policy/UI (global evaluation after building the chain):

* If **every** chain element has alt-sig **and** `pq_ok==true` → mark connection **PQ**.
* Else (missing alt-sig anywhere **or** any `pq_ok==false`) → mark **Not PQ**.

**Commit**: `feat(verify): hybrid path verification; prefer PQ, fall back classical`

---

# ⚙️ Prefs (defaults aligned to your ask)

**Step 7 — about:config**

* `security.pq.prefer_alt_sig` **default: true**
* `security.pq.require_alt_sig` **default: false** (we don’t fail the connection; we only label **Not PQ** if Dil-3 fails)

**Commit**: `feat(prefs): default to prefer alt-sig; do not require`

---

# 🖼️ UI: PQ indicator

**Step 8 — Identity UI & DevTools**

* **Lock badge**: add a small “PQ” pill next to the lock **only when PQ passed end-to-end**. If not, show **“Not PQ”** in the identity popup (no badge).
* **DevTools Security panel**:

  * “Certificate: **Hybrid (RSA-PSS + ML-DSA-65)**” when alt-sig present.
  * “PQ validation: **Passed**” or “**Not PQ**: <reason> (missing alt-sig at <issuer> / verification failed).”

Touch points: site identity panel & security viewer (exact files may vary by rev; integrate where the cert summary is rendered). NSS provides the verdict via a flag on the connection info object.

**Commit**: `feat(ui): show PQ badge on success; show 'Not PQ' otherwise`

---

# 🧪 Tests

**Step 9 — Unit tests**

* freebl: verify ML-DSA-65 positive/negative KATs using liboqs vectors. ([GitHub][2])
* x509 parser: decode 73/74; inner OID equals ML-DSA-65 (FIPS-204). ([NIST Publications][5])

**Commit**: `test: add ML-DSA-65 KATs + alt-sig parse tests`

**Step 10 — Integration tests**
Fixtures:

* **Good chain**: Root/Sub/Leaf all with 73/74 (ML-DSA-65) → UI badge **PQ**.
* **Missing alt** at Sub (or Root) → **Not PQ (missing at Sub)**.
* **Bad alt-sig** on Leaf → **Not PQ (verify failed)**; connection still loads (classical).

**Commit**: `test(integration): hybrid chain, missing-alt, and bad-alt cases`

---

# 🧭 Build & run

**Step 11 — Build with liboqs linked**

```bash
cd security/nss && ./build.sh -o
cd ../../
./mach build
./mach run
```

(Ensure freebl links against `third_party/liboqs` where the verifier lives.) ([firefox-source-docs.mozilla.org][1])
**Commit**: `docs(build): how to build Firefox with liboqs-backed PQ verify`

---

# ✅ Acceptance (what Cursor should assert)

* [ ] NSS recognizes **2.5.29.73/74** and exposes them in the cert viewer. ([docs.keyfactor.com][4])
* [ ] Dil-3 (ML-DSA-65) verify runs via **liboqs** and returns true for your good chain. ([GitHub][2])
* [ ] **UI shows “PQ”** only if **every** chain element has alt-sig **and passes** Dil-3 verify; else **“Not PQ”**.
* [ ] Connection doesn’t fail when PQ fails (since `require_alt_sig=false`).
* [ ] Docs refer to **FIPS-204** and **LAMPS ML-DSA** for identifiers. ([NIST Publications][5])

---

## One-liner to feed Cursor

> Implement Steps 2–6 now; after each step **build** and **commit** with the exact message. In Step 6, enforce: show **PQ** only if Dil-3 verification succeeds for **every** chain element; otherwise show **Not PQ** (connection still OK). Provide diffs and test outputs.

---

### References (for the implementer)

* **FIPS-204 ML-DSA** (Dilithium → ML-DSA; parameter sets inc. ML-DSA-65). ([NIST Publications][5])
* **LAMPS ML-DSA in PKIX** (algorithm identifiers in X.509). ([datatracker.ietf.org][6])
* **EJBCA Hybrid/Alternative Signature** (extensions 2.5.29.73/74). ([docs.keyfactor.com][4])
* **NSS OID tables & structure** (where to register new OIDs). ([Chromium Git Repositories][3])
* **liboqs** (Open Quantum Safe library) and releases. ([GitHub][2])

If you want, I can also add a tiny **DevTools screenshot spec** (labels/strings) so the PQ badge alignment matches Firefox’s style.

[1]: https://firefox-source-docs.mozilla.org/security/nss/legacy_extracts/structure.html?utm_source=chatgpt.com "NSS API Structure — Firefox Source Docs documentation"
[2]: https://github.com/open-quantum-safe/liboqs?utm_source=chatgpt.com "open-quantum-safe/liboqs: C library for prototyping and ..."
[3]: https://chromium.googlesource.com/chromium/third_party/nss/%2B/fe067e57da7bd24431c53ca3b29bfcda4000fe5b/mozilla/security/nss/lib/util/secoid.c?utm_source=chatgpt.com "mozilla/security/nss/lib/util/secoid.c"
[4]: https://docs.keyfactor.com/ejbca/9.0/tutorial-create-pqc-hybrid-ca-chain?utm_source=chatgpt.com "Create Post-Quantum Cryptography Hybrid CA Chain"
[5]: https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.204.pdf?utm_source=chatgpt.com "Module-Lattice-Based Digital Signature Standard (FIPS 204)"
[6]: https://datatracker.ietf.org/doc/draft-ietf-lamps-dilithium-certificates/?utm_source=chatgpt.com "draft-ietf-lamps-dilithium-certificates-12 - Internet X.509 ..."
