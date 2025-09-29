# Firefox PQ Hybrid Signatures - Build Guide

## Current Build Status

The build is in progress. Expected issues:

1. **liboqs not linked to freebl** - Will cause linker errors
2. **certpqvfy.c not in build** - Won't be compiled
3. **Missing ASN.1 templates** - May cause SEC_ASN1_GET errors

## Quick Fix: Build Without PQ Features

To build Firefox WITHOUT the PQ features (standard Firefox):

```bash
# Comment out liboqs references in ml_dsa.c
# Remove the #include <oqs/oqs.h> line
./mach build
```

## Full Build: With PQ Support

### Step 1: Build and Install liboqs

```bash
cd security/third_party/liboqs
mkdir -p build && cd build

# Configure for installation
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      ..

# Build
make -j$(nproc)

# Install (may need sudo)
sudo make install
sudo ldconfig
```

### Step 2: Update freebl Build Configuration

**File**: `security/nss/lib/freebl/freebl.gyp`

Find the `freebl_static` target and add:

```python
{
  'target_name': 'freebl_static',
  'type': 'static_library',
  'includes': [
    'freebl_base.gypi',
  ],
  'dependencies': [
    '<(DEPTH)/exports.gyp:nss_exports',
    'hw-acc-crypto-avx',
    'hw-acc-crypto-avx2',
  ],
  'include_dirs': [
    '/usr/local/include',  # Add this for liboqs headers
  ],
  'libraries': [
    '-loqs',  # Add this to link liboqs
  ],
  # ... rest of target ...
}
```

### Step 3: Add certpqvfy.c to Build

**File**: `security/nss/lib/certhigh/certhigh.gyp` (or manifest.mn)

Add to sources list:
```
certpqvfy.c
```

### Step 4: Fix ASN.1 Template References

**File**: `security/nss/lib/certdb/certdb.c`

Add at top:
```c
#include "secasn1.h"
```

The template `SEC_ASN1_GET(SECOID_AlgorithmIDTemplate)` should be available.

### Step 5: Build Firefox

```bash
# From firefox-cyqu directory
./mach build
```

## Alternative: Conditional Compilation

To make the code build-time optional:

**File**: `security/nss/lib/freebl/ml_dsa.c`

```c
#ifdef NSS_ENABLE_PQC
#include <oqs/oqs.h>
#else
// Stub implementation
SECStatus MLDSA_Verify(...) {
    PORT_SetError(SEC_ERROR_LIBRARY_FAILURE);
    return SECFailure;
}
#endif
```

Then build with:
```bash
./mach build -DNSS_ENABLE_PQC=1
```

## Expected Build Errors and Fixes

### Error 1: "oqs/oqs.h: No such file or directory"

**Fix**: Install liboqs headers or add include path:
```bash
export CFLAGS="-I/usr/local/include"
export CXXFLAGS="-I/usr/local/include"
./mach build
```

### Error 2: "undefined reference to `OQS_SIG_new`"

**Fix**: Link liboqs library. Update freebl.gyp as shown above.

### Error 3: "certpqvfy.c: No such file"

**Fix**: Add certpqvfy.c to certhigh build target in moz.build or gyp file.

### Error 4: "SEC_ASN1_GET undeclared"

**Fix**: Include secasn1.h in certdb.c

### Error 5: "SEC_BitStringTemplate undefined"

**Fix**: This template should be in NSS. If missing, define it or use existing template.

## Minimal Working Build

For quickest build to test structure:

1. **Disable liboqs calls**:
   - Comment out OQS_SIG_* calls in ml_dsa.c
   - Return SECFailure with appropriate error

2. **Don't compile certpqvfy.c yet**:
   - Remove references to CERT_VerifyAltSignature* functions
   - Or add empty stubs

3. **Build just NSS**:
```bash
cd security/nss
./build.sh -o
```

4. **Then build Firefox**:
```bash
cd ../../
./mach build
```

## Verification After Build

```bash
# Check if liboqs is linked
ldd obj-x86_64-pc-linux-gnu/security/nss/lib/freebl/libfreeblpriv3.so | grep oqs

# Check for ML-DSA symbols
nm obj-x86_64-pc-linux-gnu/security/nss/lib/freebl/libfreeblpriv3.so | grep MLDSA

# Run Firefox
./mach run
```

## Testing the Build

```bash
# Test with preference
./mach run -- -purgecaches
# In browser console:
Services.prefs.getBoolPref("security.pq.prefer_alt_sig")
# Should return: true
```

## Known Limitations

1. **liboqs must be pre-built** - Not part of Firefox build
2. **Build system not automated** - Manual gyp changes needed
3. **No Windows/macOS support yet** - Linux-only for now
4. **Test certificates required** - No way to test without PQ certs

## Troubleshooting

### Build hangs or takes too long
```bash
# Use fewer parallel jobs
./mach build -j4
```

### Out of memory
```bash
# Reduce parallelism
./mach build -j1
```

### Clean build needed
```bash
./mach clobber
./mach build
```

### NSS-only rebuild
```bash
cd security/nss
./build.sh clean
./build.sh -o
```

## Next Steps After Successful Build

1. Generate test certificates with ML-DSA signatures
2. Import test CA into Firefox
3. Visit test site
4. Check for PQ verification in about:preferences#privacy
5. Inspect certificate in DevTools

## Getting Help

Check build logs:
```bash
cat obj-x86_64-pc-linux-gnu/config.log
tail -f /tmp/firefox-build.log
```

NSS build logs:
```bash
cat security/nss/out/Release/build.log
```

For build system issues:
- See `mach help build`
- Check Mozilla build docs
- Review NSS build docs

---

**Last Updated**: 2025-09-29  
**Build Status**: In Progress - Expect linker errors due to liboqs integration
