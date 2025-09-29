# Build Notes for liboqs Integration

## Requirements

To build freebl with ML-DSA support, you need to:

### 1. Build liboqs first

```bash
cd ../../../third_party/liboqs
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=../../liboqs-install ..
make && make install
```

### 2. Add liboqs to freebl build

The following needs to be added to the build system:

**For GYP (freebl.gyp):**
- Add liboqs include path to `include_dirs` in `target_defaults`
- Add liboqs library to `libraries` for freebl_static target

**For manifest.mn:**
- No changes needed (ml_dsa.c already included in CSRCS)

**Include paths needed:**
- `../../../third_party/liboqs/build/include`
- Or: `../../../liboqs-install/include`

**Library to link:**
- `-loqs` (liboqs.a or liboqs.so)
- Library path: `../../../third_party/liboqs/build/lib` or `../../../liboqs-install/lib`

### 3. Build commands

```bash
# If using NSS build.sh:
cd security/nss
NSS_ENABLE_WERROR=0 ./build.sh -o

# If using Firefox mach build:
cd ../..
./mach build
```

## TODO for Build System

- [ ] Add liboqs as CMake external project in NSS/Firefox build
- [ ] Update freebl.gyp to add liboqs include_dirs
- [ ] Update freebl.gyp to link liboqs library  
- [ ] Test build on Linux, macOS, Windows
- [ ] Consider static vs dynamic linking for liboqs
