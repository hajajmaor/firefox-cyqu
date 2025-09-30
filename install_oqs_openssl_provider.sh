#!/bin/bash
# Install OQS-OpenSSL Provider for Hybrid Certificate Generation

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🔐 Installing OQS-OpenSSL Provider"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "This is EASIER than wolfCLU and works reliably!"
echo ""

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

# Check if liboqs is installed
if ! ldconfig -p | grep -q liboqs; then
    echo "❌ liboqs not found!"
    echo "   Installing liboqs first..."
    cd /home/kono/projects/cyqu/firefox-cyqu/security/third_party/liboqs
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_SHARED_LIBS=ON ..
    make -j$(nproc)
    sudo make install
    sudo ldconfig
    echo "✅ liboqs installed"
else
    echo "✅ liboqs already installed"
fi

# Install cmake if needed
if ! command -v cmake &> /dev/null; then
    echo "📦 Installing cmake..."
    sudo apt-get update -qq
    sudo apt-get install -y cmake
fi

# Clone OQS-OpenSSL provider
echo ""
echo "📥 Cloning OQS-OpenSSL provider..."
cd /tmp
if [ -d "oqs-provider" ]; then
    rm -rf oqs-provider
fi
git clone --depth 1 https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider

# Build
echo ""
echo "🔨 Building OQS-OpenSSL provider..."
cmake -DCMAKE_PREFIX_PATH=/usr/local -S . -B _build
cmake --build _build

# Install
echo ""
echo "📥 Installing OQS-OpenSSL provider..."
sudo cmake --install _build

# Verify
echo ""
echo "✅ Verifying installation..."
if openssl list -providers 2>/dev/null | grep -q oqsprovider; then
    echo "✅ OQS-OpenSSL provider installed successfully!"
else
    echo "⚠️  Provider installed but may need OpenSSL 3.x"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🎉 Installation Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📍 Provider installed in system OpenSSL providers directory"
echo ""
echo "🔐 Generate hybrid certificate with:"
echo ""
echo "cd /home/kono/projects/cyqu/firefox-cyqu"
echo "openssl req -new -x509 -newkey mldsa65 \\"
echo "    -keyout hybrid_key.pem -out hybrid_cert.pem \\"
echo "    -nodes -days 365 -provider oqsprovider \\"
echo "    -subj \"/CN=localhost\" \\"
echo "    -addext \"subjectAltName=DNS:localhost,IP:127.0.0.1\""
echo ""
echo "🧪 Then test with: python3 test_pq_server.py"
echo ""

cd /home/kono/projects/cyqu/firefox-cyqu
