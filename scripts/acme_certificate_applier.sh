#!/bin/bash

# Domain and DNS constants
SUBDOMAIN="INSERT SUB"
DOMAIN="INSERT DOMAIN"
TLD="INSERT TLD"

# ACME constants
FULL_CHAIN="/root/.acme.sh/${SUBDOMAIN}.${DOMAIN}.${TLD}_ecc/fullchain.cer"
PRIV_KEY="/root/.acme.sh/${SUBDOMAIN}.${DOMAIN}.${TLD}_ecc/${SUBDOMAIN}.${DOMAIN}.${TLD}.key"

# Unifi constants
CRT_FILE="/data/unifi-core/config/unifi-core.crt"
KEY_FILE="/data/unifi-core/config/unifi-core.key"

/bin/cp "${FULL_CHAIN}" "${CRT_FILE}"
/bin/cp "${PRIV_KEY}" "${KEY_FILE}"

/bin/chown root:ssl-cert "${CRT_FILE}" "${KEY_FILE}"

/bin/chmod 644 "${CRT_FILE}"
/bin/chmod 600 "${KEY_FILE}"

/bin/systemctl restart unifi-core
