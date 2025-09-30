#!/bin/bash
# Configure OpenSSL to load OQS provider

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🔧 Configuring OpenSSL for OQS Provider"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check for sudo
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access"
    echo "   Please run: sudo -v"
    exit 1
fi

# Backup original config
echo "📋 Backing up OpenSSL configuration..."
sudo cp /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf.backup || true

# Create OpenSSL config with OQS provider
echo ""
echo "⚙️  Configuring OpenSSL to load OQS provider..."

sudo tee /etc/ssl/openssl.cnf > /dev/null << 'OPENSSL_CONF'
#
# OpenSSL configuration with OQS Provider
#

openssl_conf = openssl_init

[openssl_init]
providers = provider_sect

[provider_sect]
default = default_sect
oqsprovider = oqsprovider_sect

[default_sect]
activate = 1

[oqsprovider_sect]
activate = 1
# Explicit module path
module = /usr/lib/x86_64-linux-gnu/ossl-modules/oqsprovider.so

#
# Original OpenSSL configuration below
#

HOME			= .

[ca]
default_ca	= CA_default

[CA_default]
dir		= ./demoCA
certs		= $dir/certs
crl_dir		= $dir/crl
database	= $dir/index.txt
new_certs_dir	= $dir/newcerts
certificate	= $dir/cacert.pem
serial		= $dir/serial
crlnumber	= $dir/crlnumber
crl		= $dir/crl.pem
private_key	= $dir/private/cakey.pem
x509_extensions	= usr_cert
name_opt 	= ca_default
cert_opt 	= ca_default
default_days	= 365
default_crl_days= 30
default_md	= default
preserve	= no
policy		= policy_match

[policy_match]
countryName		= match
stateOrProvinceName	= match
organizationName	= match
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional

[policy_anything]
countryName		= optional
stateOrProvinceName	= optional
localityName		= optional
organizationName	= optional
organizationalUnitName	= optional
commonName		= supplied
emailAddress		= optional

[req]
default_bits		= 2048
default_keyfile 	= privkey.pem
distinguished_name	= req_distinguished_name
attributes		= req_attributes
x509_extensions	= v3_ca
string_mask = utf8only

[req_distinguished_name]
countryName			= Country Name (2 letter code)
countryName_default		= AU
countryName_min			= 2
countryName_max			= 2
stateOrProvinceName		= State or Province Name (full name)
stateOrProvinceName_default	= Some-State
localityName			= Locality Name (eg, city)
0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= Internet Widgits Pty Ltd
organizationalUnitName		= Organizational Unit Name (eg, section)
commonName			= Common Name (e.g. server FQDN or YOUR name)
commonName_max			= 64
emailAddress			= Email Address
emailAddress_max		= 64

[req_attributes]
challengePassword		= A challenge password
challengePassword_min		= 4
challengePassword_max		= 20
unstructuredName		= An optional company name

[usr_cert]
basicConstraints=CA:FALSE
nsComment			= "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[v3_ca]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true

[crl_ext]
authorityKeyIdentifier=keyid:always

[proxy_cert_ext]
basicConstraints=CA:FALSE
nsComment			= "OpenSSL Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
proxyCertInfo=critical,language:id-ppl-anyLanguage,pathlen:3,policy:foo
OPENSSL_CONF

echo "✅ OpenSSL configuration updated"

# Test provider loading
echo ""
echo "🧪 Testing provider..."
if openssl list -providers 2>/dev/null | grep -q oqsprovider; then
    echo "✅ OQS provider is now active!"
    openssl list -providers
else
    echo "⚠️  Provider configuration may need adjustment"
    openssl list -providers 2>&1 || true
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  🎉 Configuration Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Now you can generate certificates with:"
echo ""
echo "openssl req -new -x509 -newkey mldsa65 \\"
echo "    -keyout hybrid_key.pem -out hybrid_cert.pem \\"
echo "    -nodes -days 365 \\"
echo "    -subj \"/CN=localhost\" \\"
echo "    -addext \"subjectAltName=DNS:localhost,IP:127.0.0.1\""
echo ""

cd /home/kono/projects/cyqu/firefox-cyqu

