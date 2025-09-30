#!/bin/bash
# Rebuild liboqs with ML-DSA support enabled

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🔧 Rebuilding liboqs with ML-DSA Support"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

cd /home/kono/projects/cyqu/firefox-cyqu/security/third_party/liboqs

echo "📋 Current liboqs status:"
echo "   Installed: $(grep -c "OQS_ENABLE_SIG_ml_dsa_65" /usr/local/include/oqs/oqsconfig.h 2>/dev/null || echo 0) (should be 1+)"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf build
mkdir -p build
cd build

# Configure with ML-DSA explicitly enabled
echo ""
echo "⚙️  Configuring liboqs with ML-DSA support..."
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DOQS_BUILD_ONLY_LIB=ON \
      -DOQS_ENABLE_SIG_ML_DSA=ON \
      -DOQS_ENABLE_SIG_ml_dsa_44=ON \
      -DOQS_ENABLE_SIG_ml_dsa_65=ON \
      -DOQS_ENABLE_SIG_ml_dsa_87=ON \
      ..

echo ""
echo "🔨 Building liboqs..."
make -j$(nproc)

echo ""
echo "📥 Installing liboqs..."
sudo make install
sudo ldconfig

# Verify
echo ""
echo "✅ Verifying ML-DSA is now enabled..."
if grep -q "#define OQS_ENABLE_SIG_ml_dsa_65" /usr/local/include/oqs/oqsconfig.h; then
    echo "✅ ML-DSA-65 is NOW ENABLED in liboqs!"
else
    echo "❌ ML-DSA-65 still not enabled - check cmake output"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🎉 liboqs Rebuilt Successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Now rebuild OQS-OpenSSL provider:"
echo "  cd /tmp/oqs-provider/_build"
echo "  rm -rf *"
echo "  cd .."
echo "  cmake -S . -B _build"
echo "  cmake --build _build"
echo "  sudo cmake --install _build"
echo ""
echo "Then try certificate generation again!"
echo ""

cd /home/kono/projects/cyqu/firefox-cyqu

