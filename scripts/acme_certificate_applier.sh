#!/bin/bash

# Domain and DNS constants
SUBDOMAIN="XXXXXXXXXXXXXXX"
DOMAIN="YYYYYYYYYYYYYYY"
TLD="ZZZZZZZZZZZZZ"
FQDN="${SUBDOMAIN}.${DOMAIN}.${TLD}"

# ACME constants
FULL_CHAIN="/root/.acme.sh/${FQDN}_ecc/fullchain.cer"
PRIV_KEY="/root/.acme.sh/${FQDN}_ecc/${FQDN}.key"

# Unifi constants
CRT_FILE="/data/unifi-core/config/unifi-core.crt"
KEY_FILE="/data/unifi-core/config/unifi-core.key"
KEYSTORE="/usr/lib/unifi/data/keystore"
STORE_PASS="aircontrolenterprise"

# Other constants
TEMP_P12="/tmp/unifi.p12"

# Copy the cert and key to the required location
/bin/cp "${FULL_CHAIN}" "${CRT_FILE}"
/bin/cp "${PRIV_KEY}" "${KEY_FILE}"

/bin/chown root:ssl-cert "${CRT_FILE}" "${KEY_FILE}"

/bin/chmod 644 "${CRT_FILE}"
/bin/chmod 600 "${KEY_FILE}"

# Export the key for use in the keystore
/usr/bin/openssl pkcs12 -export \
    -in "${FULL_CHAIN}" \
    -inkey "${PRIV_KEY}" \
    -out "${TEMP_P12}" \
    -name unifi \
    -password pass:"${STORE_PASS}"

# Delete the existing 'unifi' alias from keystore to avoid conflicts
/usr/bin/keytool -delete -alias unifi -keystore "${KEYSTORE}" -deststorepass "${STORE_PASS}" || true

# Import the PKCS12 into the UniFi Keystore
/usr/bin/keytool -importkeystore \
    -deststorepass "${STORE_PASS}" \
    -destkeypass "${STORE_PASS}" \
    -destkeystore "${KEYSTORE}" \
    -srckeystore "${TEMP_P12}" \
    -srcstoretype PKCS12 \
    -srcstorepass "${STORE_PASS}" \
    -alias unifi \
    -noprompt

# 3. Cleanup and Restart
rm "${TEMP_P12}"

# Restart services to apply changes
/bin/systemctl restart unifi-core && /bin/systemctl restart unifi
