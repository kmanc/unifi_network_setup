#!/bin/bash
set -euo pipefail

# Domain and DNS constants
SUBDOMAIN="XXXXXXXXXXXXXXX"
DOMAIN="YYYYYYYYYYYYYYY"
TLD="ZZZZZZZZZZZZZ"
FQDN="${SUBDOMAIN}.${DOMAIN}.${TLD}"

# ACME constants
FULL_CHAIN="/root/.acme.sh/${FQDN}/fullchain.cer"
PRIV_KEY="/root/.acme.sh/${FQDN}/${FQDN}.key"

# Unifi constants
CRT_FILE="/data/unifi-core/config/unifi-core.crt"
KEY_FILE="/data/unifi-core/config/unifi-core.key"
KEYSTORE="/usr/lib/unifi/data/keystore"
STORE_PASS="aircontrolenterprise"

# Other constants
TEMP_P12="/tmp/unifi.p12"

# -----------------------------------------------------------
# Pre-flight: abort early if source certs are missing/empty
# -----------------------------------------------------------
if [[ ! -s "${FULL_CHAIN}" ]]; then
    echo "ERROR: fullchain cert not found or empty: ${FULL_CHAIN}" >&2
    exit 1
fi

if [[ ! -s "${PRIV_KEY}" ]]; then
    echo "ERROR: private key not found or empty: ${PRIV_KEY}" >&2
    exit 1
fi

# Verify the cert and key actually match
CERT_MOD=$(/usr/bin/openssl x509 -noout -modulus -in "${FULL_CHAIN}" | /usr/bin/openssl md5)
KEY_MOD=$(/usr/bin/openssl rsa -noout -modulus -in "${PRIV_KEY}" | /usr/bin/openssl md5)
if [[ "${CERT_MOD}" != "${KEY_MOD}" ]]; then
    echo "ERROR: certificate and private key do not match" >&2
    exit 1
fi

# -----------------------------------------------------------
# Build the PKCS12 bundle and validate it BEFORE touching
# the keystore
# -----------------------------------------------------------
/usr/bin/openssl pkcs12 -export \
    -in "${FULL_CHAIN}" \
    -inkey "${PRIV_KEY}" \
    -out "${TEMP_P12}" \
    -name unifi \
    -password pass:"${STORE_PASS}"

if [[ ! -s "${TEMP_P12}" ]]; then
    echo "ERROR: PKCS12 export produced empty file" >&2
    exit 1
fi

# Copy the cert and key to the required location
/bin/cp "${FULL_CHAIN}" "${CRT_FILE}"
/bin/cp "${PRIV_KEY}" "${KEY_FILE}"

/bin/chown root:ssl-cert "${CRT_FILE}" "${KEY_FILE}"
/bin/chmod 644 "${CRT_FILE}"
/bin/chmod 600 "${KEY_FILE}"

# -----------------------------------------------------------
# Back up the current keystore, then do the delete + import
# -----------------------------------------------------------
if [[ -f "${KEYSTORE}" ]]; then
    /bin/cp "${KEYSTORE}" "${KEYSTORE}.bak"
fi

/usr/bin/keytool -delete -alias unifi \
    -keystore "${KEYSTORE}" \
    -deststorepass "${STORE_PASS}" 2>/dev/null || true

if ! /usr/bin/keytool -importkeystore \
    -deststorepass "${STORE_PASS}" \
    -destkeypass "${STORE_PASS}" \
    -destkeystore "${KEYSTORE}" \
    -srckeystore "${TEMP_P12}" \
    -srcstoretype PKCS12 \
    -srcstorepass "${STORE_PASS}" \
    -alias unifi \
    -noprompt; then

    echo "ERROR: keystore import failed — restoring backup" >&2
    if [[ -f "${KEYSTORE}.bak" ]]; then
        /bin/cp "${KEYSTORE}.bak" "${KEYSTORE}"
    fi
    rm -f "${TEMP_P12}"
    exit 1
fi

# -----------------------------------------------------------
# Verify the alias actually landed in the keystore
# -----------------------------------------------------------
if ! /usr/bin/keytool -list -alias unifi \
    -keystore "${KEYSTORE}" \
    -storepass "${STORE_PASS}" > /dev/null 2>&1; then

    echo "ERROR: 'unifi' alias missing after import — restoring backup" >&2
    if [[ -f "${KEYSTORE}.bak" ]]; then
        /bin/cp "${KEYSTORE}.bak" "${KEYSTORE}"
    fi
    rm -f "${TEMP_P12}"
    exit 1
fi

# Cleanup
rm -f "${TEMP_P12}"

# Restart services to apply changes
/bin/systemctl restart unifi-core && /bin/systemctl restart unifi

echo "Certificate updated successfully for ${FQDN}"
