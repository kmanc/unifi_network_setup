#!/bin/bash

# Keystore constants
PASSWORD="INSERT_PASSWORD_HERE"

# Let's Encrypt constants
DOMAIN="INSERT_DOMAIN_HERE"
LE_FULL_CHAIN="/etc/letsencrypt/live/INSERT_SUBDOMAIN.DOMAIN.TLD_HERE/fullchain.pem"
LE_PRIV_KEY="/etc/letsencrypt/live/INSERT_SUBDOMAIN.DOMAIN.TLD_HERE/privkey.pem"
TLD="INSERT_TLD_HERE"

# Unifi constants
CRT_FILE="/data/unifi-core/config/unifi-core.crt"
KEY_FILE="/data/unifi-core/config/unifi-core.key"

/bin/cp "${LE_FULL_CHAIN}" "${CRT_FILE}"
/bin/cp "${LE_PRIV_KEY}" "${KEY_FILE}"

/usr/bin/openssl pkcs12 -export -in "${LE_FULL_CHAIN}" -inkey "${LE_PRIV_KEY}" -out "/data/unifi-core/config/${DOMAIN}.${TLD}.p12" -name unifi -password pass:"${PASSWORD}"
/usr/bin/keytool -importkeystore -srckeystore "/data/unifi-core/config/${DOMAIN}.${TLD}.p12" -srcstoretype PKCS12 -srcstorepass ${PASSWORD} -destkeystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -alias unifi -noprompt
/bin/systemctl restart unifi
