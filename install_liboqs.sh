#!/bin/bash
# Install liboqs library for ML-DSA verification

set -e

echo "🔐 Installing liboqs for Post-Quantum Cryptography"
echo "=================================================="
echo ""

# Check if we have sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

cd security/third_party/liboqs

# Clean any previous builds
rm -rf build
mkdir -p build
cd build

echo "📦 Step 1: Configuring liboqs with cmake..."
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DOQS_BUILD_ONLY_LIB=ON \
      -DOQS_MINIMAL_BUILD="OQS_ENABLE_SIG_dilithium_2;OQS_ENABLE_SIG_dilithium_3;OQS_ENABLE_SIG_dilithium_5" \
      ..

echo ""
echo "🔨 Step 2: Building liboqs (this may take a few minutes)..."
make -j$(nproc)

echo ""
echo "📥 Step 3: Installing liboqs to /usr/local..."
sudo make install

echo ""
echo "🔗 Step 4: Updating library cache..."
sudo ldconfig

echo ""
echo "✅ liboqs installed successfully!"
echo ""
echo "📍 Library location: /usr/local/lib/liboqs.so"
echo "📍 Headers location: /usr/local/include/oqs/"
echo ""
echo "🧪 Verify installation:"
echo "   ldconfig -p | grep liboqs"
echo ""

# Verify
if ldconfig -p | grep -q liboqs; then
    echo "✅ Verification passed - liboqs is available"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. ./mach build"
    echo "   2. ./mach run"
    echo "   3. Test with hybrid certificates!"
else
    echo "⚠️  Warning: liboqs not found in ldconfig"
    echo "   You may need to run: sudo ldconfig"
fi

cd ../../../..
