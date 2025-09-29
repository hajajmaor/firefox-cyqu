# liboqs Installation - Manual Step Required

## ⚠️ Requires Sudo Access

To enable full ML-DSA verification, you need to install liboqs. This requires sudo access.

### Quick Install (5 minutes)

```bash
# 1. Install build dependencies
sudo apt-get update
sudo apt-get install -y cmake ninja-build

# 2. Build liboqs
cd /home/kono/projects/cyqu/firefox-cyqu/security/third_party/liboqs
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      ..

make -j$(nproc)

# 3. Install (requires sudo)
sudo make install
sudo ldconfig

# 4. Verify installation
ls -la /usr/local/lib/liboqs*
ls -la /usr/local/include/oqs/
```

### Then: Uncomment Real Implementation

See `WHATS_NEXT.md` for instructions to uncomment the real ML-DSA code.

---

**Status**: Postponed - requires manual sudo intervention  
**Impact**: ML-DSA verification returns error (stubbed), but Firefox works fine  
**When to do**: When you want real PQ signature verification
