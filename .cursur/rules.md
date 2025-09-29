# 📋 Implementation Rules & Guidelines

**Project**: Firefox NSS ML-DSA-65 Hybrid Signatures

---

## 🎯 Core Principles

### 1. Security First
- ✅ Classical signature verification is **always** required and authoritative
- ✅ PQ signature verification is **additive** and informational
- ✅ Never compromise existing security for PQ features
- ✅ Fail safely: errors in PQ verification → mark "Not PQ", but allow connection

### 2. Conservative Defaults
- ✅ Default to **prefer** PQ but not **require** it
- ✅ Show "PQ" badge only when we're **100% certain** all PQ verifications passed
- ✅ When in doubt, mark "Not PQ" with clear reasoning

### 3. Minimal Invasiveness
- ✅ Verify-only implementation (no PQ key generation or signing in this phase)
- ✅ Use liboqs as library (don't reimplement crypto)
- ✅ Minimize changes to existing NSS code paths
- ✅ Add new code paths rather than modifying existing ones when possible

---

## 🔨 Coding Standards

### General
- Follow existing Firefox/NSS code style
- Use descriptive variable names
- Comment complex logic, especially crypto operations
- Prefer readability over cleverness

### NSS-Specific
- Use NSS types: `SECStatus`, `SECItem`, `PRBool`, etc.
- Follow NSS error handling patterns (return `SECFailure`, set error code)
- Use NSS memory management (`PORT_Alloc`, `PORT_Free`)
- Check for NULL before dereferencing

### Comments & Documentation
- Explain **why** not just **what**
- Reference RFCs/specs for crypto operations
- Document assumptions and invariants
- Add TODO comments for future enhancements

---

## 📝 Commit Guidelines

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `chore`: Maintenance task
- `test`: Adding/updating tests
- `docs`: Documentation only
- `build`: Build system changes

### Scope
- `nss`: NSS-related changes
- `freebl`: freebl library changes
- `oids`: OID registration
- `x509`: Certificate parsing
- `verify`: Verification logic
- `prefs`: Preferences
- `ui`: User interface
- `liboqs`: liboqs integration

### Subject
- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at the end
- Max 72 characters

### Example
```
feat(freebl): ML-DSA-65 verify via liboqs (verify-only)

Implement wrapper around liboqs OQS_SIG_dilithium_3 verify function.
This adds oqs_dilithium_verify() which takes public key, message,
and signature, and returns SECSuccess/SECFailure.

Refs: FIPS-204, liboqs API v0.10.0
```

---

## 🧪 Testing Requirements

### Before Each Commit
- [ ] Build completes without errors: `./mach build`
- [ ] No new compiler warnings
- [ ] Existing tests still pass
- [ ] New code has test coverage

### Test Philosophy
- **Unit tests**: Test individual functions in isolation
- **Integration tests**: Test end-to-end flows with real certs
- **Negative tests**: Test error cases and edge cases
- **KAT (Known Answer Tests)**: Use official test vectors

### Test Fixtures
- Keep test certificates in `security/nss/tests/chains/`
- Document what each test cert represents
- Include both valid and invalid cases

---

## 🚨 What to Watch For

### Security Considerations
- ⚠️ Never skip classical signature verification
- ⚠️ Validate OID matches before using PQ verification
- ⚠️ Check signature length matches expected for algorithm
- ⚠️ Verify TBS bytes are identical for both signatures
- ⚠️ Don't trust extension data without validation

### Common Pitfalls
- ⚠️ Off-by-one errors in ASN.1 parsing
- ⚠️ Memory leaks (especially with `SECItem` buffers)
- ⚠️ Integer overflow in length calculations
- ⚠️ Mixing up OID for algorithm vs OID for extension
- ⚠️ Threading issues (NSS may verify certs in parallel)

### Performance
- ⚠️ PQ signatures are larger (ML-DSA-65: ~3293 bytes)
- ⚠️ PQ verification is slower than RSA/ECDSA
- ⚠️ Don't verify PQ signature multiple times per cert
- ⚠️ Cache verification results when possible

---

## 🔄 Build & Test Workflow

### Standard Workflow
```bash
# 1. Make changes
vim security/nss/lib/freebl/oqs_dilithium.c

# 2. Build NSS
cd security/nss && ./build.sh -o

# 3. Build Firefox
cd ../../
./mach build

# 4. Run tests
./mach test security/nss/tests/

# 5. Manual test
./mach run

# 6. Commit
git add -A
git commit -m "feat(freebl): add oqs_dilithium wrapper"
```

### Quick Iteration (for NSS-only changes)
```bash
# Just rebuild NSS, skip full Firefox build
cd security/nss && ./build.sh -o && cd ../../
```

---

## 📋 Code Review Checklist

Before marking a step complete:

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] New code has comments explaining logic
- [ ] Memory is properly managed (no leaks)
- [ ] Error cases are handled
- [ ] Code follows NSS/Firefox style
- [ ] Commit message is descriptive
- [ ] Documentation is updated if needed

---

## 🎓 Learning Resources

### NSS Documentation
- [NSS Structure](https://firefox-source-docs.mozilla.org/security/nss/legacy_extracts/structure.html)
- [NSS Crypto Functions](https://firefox-source-docs.mozilla.org/security/nss/)

### Cryptography
- [FIPS-204 ML-DSA Standard](https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.204.pdf)
- [LAMPS Dilithium Certificates Draft](https://datatracker.ietf.org/doc/draft-ietf-lamps-dilithium-certificates/)

### X.509 Extensions
- [RFC 5280: X.509 PKI](https://datatracker.ietf.org/doc/html/rfc5280)
- [EJBCA Hybrid Signatures](https://docs.keyfactor.com/ejbca/9.0/tutorial-create-pqc-hybrid-ca-chain)

---

**Last Updated**: 2025-09-29
