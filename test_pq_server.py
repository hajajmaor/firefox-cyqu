#!/usr/bin/env python3
# Simple HTTPS Test Server for PQ Certificate Testing

import http.server
import ssl
import sys
import os

PORT = 8443

class TestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        
        html = """<!DOCTYPE html>
<html>
<head>
    <title>🔐 PQ Certificate Test</title>
    <style>
        body { font-family: Arial; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0c8; }
        .success { color: green; font-size: 1.2em; font-weight: bold; }
        .code { background: #f0f0f0; padding: 15px; border-left: 4px solid #0c8; margin: 15px 0; font-family: monospace; }
        .info { background: #e8f4f8; padding: 15px; margin: 15px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔐 Post-Quantum Certificate Test Server</h1>
        <p class="success">✅ HTTPS Connection Successful!</p>
        
        <div class="info">
            <h2>Expected Certificate Properties:</h2>
            <ul>
                <li><strong>Classical Algorithm:</strong> RSA-2048 or ECDSA-P256</li>
                <li><strong>Post-Quantum Algorithm:</strong> ML-DSA-65 (Dilithium-3)</li>
                <li><strong>Extension 2.5.29.73:</strong> Alternative Signature Algorithm</li>
                <li><strong>Extension 2.5.29.74:</strong> Alternative Signature Value</li>
            </ul>
        </div>
        
        <h2>🧪 Test in Firefox Console</h2>
        <p>Press <strong>Ctrl+Shift+J</strong> to open Browser Console, then run:</p>
        <div class="code">
let secInfo = gBrowser.securityUI.securityInfo;<br>
console.log("PQ Status:", secInfo.pqProtectionStatus);<br>
console.log("Message:", secInfo.pqStatusMessage);<br>
console.log("Is Protected:", secInfo.isPQProtected);<br>
        </div>
        
        <div class="info">
            <h3>Expected Results:</h3>
            <ul>
                <li><strong>PQ Status:</strong> "pq-protected" (if liboqs enabled) or "pq-missing" (if stubbed)</li>
                <li><strong>Message:</strong> "Protected by ML-DSA-65" or "Classical cryptography only"</li>
                <li><strong>Is Protected:</strong> true or false</li>
            </ul>
        </div>
        
        <h2>📋 Setup Checklist</h2>
        <ol>
            <li>✅ Generate hybrid certificates (see TESTING_WITH_HYBRID_CERTS.md)</li>
            <li>✅ Import root CA in Firefox (Settings → Certificates → Import)</li>
            <li>⏳ Install liboqs library (optional for real verification)</li>
            <li>⏳ Uncomment ML-DSA code in ml_dsa.c (optional)</li>
            <li>⏳ Rebuild Firefox (optional)</li>
        </ol>
        
        <p><strong>Note:</strong> Even without liboqs, the API works! You can test the framework right now.</p>
    </div>
</body>
</html>"""
        self.wfile.write(html.encode('utf-8'))

def main():
    # Check for certificate files
    cert_file = 'server-cert.pem'
    key_file = 'server-key.pem'
    
    if not os.path.exists(cert_file) or not os.path.exists(key_file):
        print("❌ Error: Certificate files not found!")
        print(f"   Missing: {cert_file} or {key_file}")
        print("\n📝 To generate self-signed certificate for testing:")
        print("   openssl req -x509 -newkey rsa:2048 -nodes \\")
        print(f"     -keyout {key_file} -out {cert_file} -days 365 \\")
        print('     -subj "/CN=localhost"')
        print("\n   Then run this script again.")
        return 1
    
    # Create server
    httpd = http.server.HTTPServer(('localhost', PORT), TestHandler)
    
    # Configure SSL
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(cert_file, key_file)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    
    print("🚀 PQ Test Server Starting...")
    print(f"🌐 URL: https://localhost:{PORT}")
    print(f"📜 Certificate: {cert_file}")
    print(f"🔑 Key: {key_file}")
    print("\n💡 Visit the URL in Firefox to test PQ implementation")
    print("⏹️  Press Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped")
        return 0

if __name__ == '__main__':
    sys.exit(main())
