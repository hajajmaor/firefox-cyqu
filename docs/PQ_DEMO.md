# PQ Demo (Firefox fork + nginx)

## Overview

This Firefox fork implements hybrid Post-Quantum (PQ) cryptography by default, combining classical and quantum-resistant algorithms for enhanced future security.

## Server Setup

### Prerequisites

- Docker and Docker Compose
- EJBCA-issued certificates with Dilithium-3 alternative signatures (optional, for full PQ status)

### Starting the Server

```bash
cd pqtls-demo
docker compose up -d
```

### Certificate Placement

Place your certificates in `pqtls-demo/tls/`:
- `server.pem` - Leaf certificate followed by intermediate chain (with alt-sig extension if available)
- `server.key` - RSA private key for RSA-PSS signature algorithm

The nginx server is configured to:
- Negotiate `x25519_kyber768` hybrid KEX when the client supports it
- Gracefully fall back to classical X25519 or secp256r1 if needed
- Forward the negotiated group information in the `X-TLS-Group` header to the FastAPI backend

### Verifying the Server

Check that the server is running and OQS provider is loaded:

```bash
# Check if containers are running
docker compose ps

# Verify OQS provider supports Kyber
docker exec -it nginx-pq openssl list -kem-algorithms | grep -i kyber

# Test the endpoint
curl -vk --tlsv1.3 https://demo.cyqu.org/about
# Note: Add demo.cyqu.org to /etc/hosts if testing locally:
# 127.0.0.1 demo.cyqu.org
```

## Client (Firefox Fork)

### Features Implemented

1. **Hybrid KEX Enabled by Default**
   - Preference `security.tls.enable_kyber` is set to `true` by default
   - Sends additional key shares for both classical and hybrid groups
   - Prefers `X25519+ML-KEM-768` (hybrid) over classical-only algorithms

2. **Negotiated Group Tracking**
   - Captures the negotiated key exchange group from NSS
   - Exposes it via `nsITransportSecurityInfo.negotiatedGroup`
   - Sets `pqKex` flag when hybrid KEX is successfully negotiated

3. **Dilithium-3 Alternative Signature Verification (Stub)**
   - Infrastructure in place to verify Dilithium-3 signatures from certificate alt-sig extensions
   - Currently a stub implementation returning `Unknown` status
   - Full implementation requires:
     - Parsing X.509 alt-sig extension OID
     - Extracting Dilithium-3 public key and signature
     - Verifying signature over TBSCertificate using liboqs
   - Sets `altSigDil3` flag when verification succeeds

4. **Identity Panel PQ Status Display**
   - Shows Post-Quantum status in the browser's identity (lock icon) panel
   - Three possible states:
     - **"PQ (Dil-3)"** - Hybrid KEX negotiated AND Dilithium-3 alt-sig verified
     - **"PQ (KEX-only)"** - Hybrid KEX negotiated but no alt-sig verified
     - **"Not PQ"** - Classical cryptography only

### Building Firefox

```bash
./mach build
```

### Running Firefox

```bash
./mach run
```

### Testing the PQ Implementation

1. Start the nginx server (see Server Setup above)
2. Run the Firefox fork
3. Navigate to `https://demo.cyqu.org`
4. Click the lock icon in the address bar to open the identity panel
5. Look for the "Post-Quantum" status line

### Verifying with Network Analysis (Optional)

To inspect the TLS handshake and confirm hybrid KEX:

1. Set `SSLKEYLOGFILE` environment variable before running Firefox:
   ```bash
   export SSLKEYLOGFILE=/tmp/sslkeys.log
   ./mach run
   ```

2. Capture traffic with Wireshark or tshark:
   ```bash
   tshark -i any -f "host demo.cyqu.org" -w /tmp/capture.pcapng
   ```

3. Open the capture in Wireshark:
   - Configure SSL/TLS preferences to use the key log file
   - Filter for `tls.handshake.type == 1` (ClientHello)
   - Expand `Extension: key_share` to see offered groups
   - Look for `x25519_kyber768` (0x6399) in the KeyShareEntry list
   - In ServerHello, verify the selected group matches

## Architecture

### Client-Side Changes

- **`modules/libpref/init/StaticPrefList.yaml`** - Enable Kyber by default
- **`security/manager/ssl/nsNSSIOLayer.cpp`** - Configure NSS to prefer hybrid groups and send additional keyshares
- **`security/manager/ssl/NSSSocketControl.*`** - Add fields to track negotiated group and PQ status
- **`security/manager/ssl/nsITransportSecurityInfo.idl`** - Expose PQ status to JavaScript
- **`security/manager/ssl/nsNSSCallbacks.cpp`** - Capture negotiated group during handshake
- **`security/manager/ssl/PQAltSigVerifier.*`** - Dilithium-3 alt-sig verification stub
- **`security/manager/ssl/SSLServerCertVerification.cpp`** - Hook alt-sig verification into cert validation
- **`browser/base/content/browser-siteIdentity.js`** - Display PQ status in identity panel UI

### Server-Side Stack

- **nginx 1.28.0** - TLS termination with OpenSSL 3.x
- **OQS Provider** (main branch) - Adds PQ algorithm support to OpenSSL
- **FastAPI** - Simple Python backend for demo endpoints
- **Docker Compose** - Orchestrates both services

## Next Steps / Future Work

1. **Complete Dilithium-3 Alt-Sig Verification**
   - Integrate liboqs library into Firefox build
   - Parse X.509 alt-sig extension (identify OID, extract signature and public key)
   - Verify signature over TBSCertificate
   - Return proper `Verified`/`Failed` status instead of `Unknown`

2. **Certificate Issuance**
   - Use EJBCA or similar CA to generate hybrid certificates with:
     - Classical RSA-PSS signature (for standard validation)
     - Dilithium-3 alternative signature in an extension
   - Deploy these certificates to the nginx server

3. **Enhanced UI**
   - Show more details about the negotiated group (e.g., "X25519 + ML-KEM-768")
   - Display certificate fingerprints and alt-sig status in "More Information" view
   - Add visual indicator (icon) next to lock when PQ is active

4. **Telemetry**
   - Track how often hybrid KEX is negotiated vs. classical
   - Monitor alt-sig verification success/failure rates
   - Report TLS intolerance issues related to PQ algorithms

5. **Fallback Mechanism**
   - Keep `security.tls.enable_kyber` toggle for users
   - If middleboxes break with large ClientHello, allow graceful degradation
   - Detect and remember sites that fail with PQ enabled

6. **Performance Testing**
   - Measure handshake time impact of hybrid KEX
   - Benchmark Dilithium-3 verification overhead
   - Optimize key generation and exchange for production use

## Troubleshooting

### Firefox doesn't show "PQ (KEX-only)" status

- Verify that `security.tls.enable_kyber` is `true` in `about:config`
- Check if the server actually negotiated a hybrid group by inspecting browser console
- Ensure NSS library version supports `ssl_grp_kem_mlkem768x25519`

### nginx fails to start

- Check that `pqtls-demo/tls/server.pem` and `server.key` exist
- Verify certificate and key are valid: `openssl x509 -in tls/server.pem -text -noout`
- Check container logs: `docker compose logs nginx-pq`

### "Not PQ" status shown even with hybrid server

- Confirm server offers `x25519_kyber768` in supported groups
- Check if TLS version is 1.3 (PQ algorithms require TLS 1.3)
- Verify client sends Kyber keyshare in ClientHello (use Wireshark)

### Build errors

- Ensure Firefox build environment is properly configured
- Run `./mach bootstrap` to install dependencies
- Check that NSS is recent enough to support experimental PQ features

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [ML-KEM (Kyber) FIPS 203](https://csrc.nist.gov/pubs/fips/203/final)
- [ML-DSA (Dilithium) FIPS 204](https://csrc.nist.gov/pubs/fips/204/final)
- [Open Quantum Safe](https://openquantumsafe.org/)
- [IETF Hybrid Key Exchange in TLS 1.3](https://datatracker.ietf.org/doc/draft-ietf-tls-hybrid-design/)

## License

This Firefox fork retains the Mozilla Public License 2.0. See [LICENSE](../LICENSE) for details.

