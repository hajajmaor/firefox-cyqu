#!/bin/bash
# Quick setup script for testing PQ implementation

set -e

echo "🔐 Firefox PQ Testing - Quick Setup"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "test_pq_server.py" ]; then
    echo "❌ Error: Run this script from the firefox-cyqu directory"
    exit 1
fi

echo "📝 Step 1: Generating self-signed test certificate..."
if [ ! -f "server-cert.pem" ] || [ ! -f "server-key.pem" ]; then
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout server-key.pem -out server-cert.pem -days 365 \
        -subj "/C=US/ST=Test/L=Test/O=PQ Test/CN=localhost" \
        2>/dev/null
    echo "   ✅ Certificate generated (server-cert.pem, server-key.pem)"
else
    echo "   ℹ️  Certificates already exist, skipping..."
fi

echo ""
echo "🔧 Step 2: Checking Python..."
if command -v python3 &> /dev/null; then
    echo "   ✅ Python 3 found: $(python3 --version)"
else
    echo "   ❌ Python 3 not found. Please install python3."
    exit 1
fi

echo ""
echo "🦊 Step 3: Firefox setup instructions"
echo "   You need to import the test certificate in Firefox:"
echo "   1. ./mach run"
echo "   2. Go to: about:preferences#privacy"
echo "   3. Scroll to 'Certificates' → Click 'View Certificates'"
echo "   4. 'Authorities' tab → Click 'Import...'"
echo "   5. Select: $(pwd)/server-cert.pem"
echo "   6. Check 'Trust this CA to identify websites'"
echo ""

echo "🚀 Step 4: Ready to test!"
echo ""
echo "To start the test server, run:"
echo "   python3 test_pq_server.py"
echo ""
echo "Then in Firefox:"
echo "   1. Visit: https://localhost:8443"
echo "   2. Open console (Ctrl+Shift+J)"
echo "   3. Run:"
echo "      let secInfo = gBrowser.securityUI.securityInfo;"
echo "      console.log('PQ Status:', secInfo.pqProtectionStatus);"
echo ""
echo "Expected result: 'pq-missing' (normal - no real PQ cert yet)"
echo "This proves the API works! ✅"
echo ""
echo "📚 For hybrid certificates with real ML-DSA signatures, see:"
echo "   TESTING_WITH_HYBRID_CERTS.md"
echo ""
