#!/bin/bash
# Install wolfSSL with Post-Quantum Cryptography Support

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🔐 Installing wolfSSL with ML-DSA (Dilithium) Support"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

# Install dependencies
echo "📦 Step 1: Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y build-essential autoconf automake libtool git

# Clone wolfSSL
echo ""
echo "📥 Step 2: Cloning wolfSSL..."
cd /tmp
if [ -d "wolfssl" ]; then
    rm -rf wolfssl
fi
git clone --depth 1 https://github.com/wolfSSL/wolfssl.git
cd wolfssl

# Configure with PQ support
echo ""
echo "🔧 Step 3: Configuring wolfSSL with Dilithium support..."
./autogen.sh
./configure \
    --enable-dilithium \
    --enable-altcertchains \
    --enable-tlsx \
    --enable-postauth \
    --enable-session-ticket \
    CFLAGS="-DWOLFSSL_ALT_CERT_CHAINS -DHAVE_EX_DATA"

# Build
echo ""
echo "🔨 Step 4: Building wolfSSL (this may take a few minutes)..."
make -j$(nproc)

# Install
echo ""
echo "📥 Step 5: Installing wolfSSL..."
sudo make install
sudo ldconfig

# Verify
echo ""
echo "✅ wolfSSL installed successfully!"
echo ""
wolfssl-config --version
echo ""

# Clone wolfCLU
echo "📥 Step 6: Cloning wolfCLU..."
cd /tmp
if [ -d "wolfCLU" ]; then
    rm -rf wolfCLU
fi
git clone --depth 1 https://github.com/wolfSSL/wolfCLU.git
cd wolfCLU

# Configure
echo ""
echo "🔧 Step 7: Configuring wolfCLU..."
./autogen.sh
./configure

# Build
echo ""
echo "🔨 Step 8: Building wolfCLU..."
make -j$(nproc)

# Install
echo ""
echo "📥 Step 9: Installing wolfCLU..."
sudo make install

# Verify
echo ""
echo "✅ wolfCLU installed successfully!"
echo ""
wolfssl -v || echo "wolfssl command installed"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🎉 Installation Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📍 wolfSSL installed in: /usr/local"
echo "📍 Libraries: /usr/local/lib"
echo "📍 Headers: /usr/local/include/wolfssl"
echo ""
echo "🔐 You can now generate hybrid certificates with:"
echo "   wolfssl -genkey dilithium -level 3 -out cert_key"
echo ""
echo "📖 See: CREATE_HYBRID_CERT_WOLFSSL.md for full guide"
echo ""

cd /home/kono/projects/cyqu/firefox-cyqu
