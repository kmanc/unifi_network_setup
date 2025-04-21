#!/bin/bash

# Domain and DNS constants
DOMAIN="INSERT_DOMAIN"
SUBDOMAIN="INSERT_SUBDOMAIN"
TLD="INSERT TLD"

# Let's Encrypt constants
LE_FULL_CHAIN="/etc/letsencrypt/live/${SUBDOMAIN}.${DOMAIN}.${TLD}/fullchain.pem"
LE_PRIV_KEY="/etc/letsencrypt/live/${SUBDOMAIN}.${DOMAIN}.${TLD}/privkey.pem"

# Unifi constants
CORE_BASE="/data/unifi-core/config"
CRT_FILE="${CORE_BASE}/unifi-core.crt"
KEY_FILE="${CORE_BASE}/unifi-core.key"

/bin/cp "${LE_FULL_CHAIN}" "${CRT_FILE}"
/bin/cp "${LE_PRIV_KEY}" "${KEY_FILE}"

/bin/systemctl restart unifi
