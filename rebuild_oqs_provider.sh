#!/bin/bash
# Rebuild OQS-OpenSSL Provider with new liboqs

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🔧 Rebuilding OQS-OpenSSL Provider"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

cd /tmp/oqs-provider

# Clean with sudo (because previous install created root-owned files)
echo "🧹 Cleaning previous build..."
sudo rm -rf _build
mkdir -p _build

# Configure
echo ""
echo "⚙️  Configuring OQS provider..."
cd _build
cmake ..

# Build
echo ""
echo "🔨 Building OQS provider..."
make -j$(nproc)

# Install
echo ""
echo "📥 Installing OQS provider..."
sudo make install

# Verify
echo ""
echo "✅ Verifying ML-DSA algorithms are available..."
if openssl list -signature-algorithms -provider-path /usr/lib/x86_64-linux-gnu/ossl-modules -provider oqsprovider -provider default 2>/dev/null | grep -qi "mldsa"; then
    echo "✅ ML-DSA algorithms are NOW AVAILABLE!"
    echo ""
    openssl list -signature-algorithms -provider-path /usr/lib/x86_64-linux-gnu/ossl-modules -provider oqsprovider -provider default 2>/dev/null | grep -i mldsa | head -5
else
    echo "⚠️  ML-DSA not found - check liboqs installation"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🎉 OQS Provider Rebuilt!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Now generate certificate:"
echo ""
echo "cd /home/kono/projects/cyqu/firefox-cyqu"
echo "openssl req -new -x509 -newkey mldsa65 \\"
echo "    -keyout hybrid_key.pem -out hybrid_cert.pem \\"
echo "    -nodes -days 365 \\"
echo "    -provider-path /usr/lib/x86_64-linux-gnu/ossl-modules \\"
echo "    -provider oqsprovider -provider default \\"
echo "    -subj \"/CN=localhost\" \\"
echo "    -addext \"subjectAltName=DNS:localhost,IP:127.0.0.1\""
echo ""

cd /home/kono/projects/cyqu/firefox-cyqu

