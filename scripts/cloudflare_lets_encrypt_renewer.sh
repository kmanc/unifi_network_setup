#!/bin/bash

# Cloudflare constants
API_BASE="https://api.cloudflare.com/client/"
API_ENDPOINT="zones/INSERT_ZONE_ID/dns_records"
API_KEY="INSERT_API_KEY"
API_VERSION="v4/"

# Domain and DNS constants
ACME="_acme-challenge"
DOMAIN="INSERT_DOMAIN"
EMAIL="INSERT_EMAIL"
SUBDOMAIN="INSERT_SUBDOMAIN"
TLD="INSERT TLD"

# Let's Encrypt constants
LE_BASE="/etc/letsencrypt"
LE_ARCHIVE_BASE="${LE_BASE}/archive"
LE_ARCHIVE_LOCATION="${LE_ARCHIVE_BASE}/${SUBDOMAIN}.${DOMAIN}.${TLD}"
LE_LIVE_BASE="${LE_BASE}/live"
LE_LIVE_LOCATION="${LE_LIVE_BASE}/${SUBDOMAIN}.${DOMAIN}.${TLD}"
LE_FULL_CHAIN=$(readlink -f "${LE_LIVE_LOCATION}/fullchain.pem")
LE_PRIV_KEY=$(readlink -f "${LE_LIVE_LOCATION}/privkey.pem")

# Unifi constants
CORE_BASE="/data/unifi-core/config"
CRT_FILE="${CORE_BASE}/unifi-core.crt"
KEY_FILE="${CORE_BASE}/unifi-core.key"

# Other constants
SLEEP_TIME=120

# Variable for tracking the ID of the TXT record so it can be deleted later
record_id=""

# Variable for tracking which line that needs to be read for the DNS TXT challenge
txt_record_line=-1

# Make sure python3 is installed
if ! command -v python3 &>/dev/null; then
    apt update && apt install -y python3
fi

# Make sure pip is also installed
if ! command -v pip3 &>/dev/null; then
    apt install -y python3-pip
fi

# Finally, make sure certbot is installed
if ! command -v certbot  &>/dev/null; then
    pip3 install certbot
fi

# Run certbot command and capture output line by line
while IFS= read -r line; do

    # Check if the line is the setup to the TXT record required
    if [[ "$line" == *"with the following value:"* ]]; then
        # Set a flag to read two lines later, which is where the TXT record actually is
        txt_record_line=2

    elif [ "$txt_record_line" -eq 0 ]; then
        # In an abundance of caution, strip leading and trailing white space
        trimmed_txt_record="${line#"${line%%[![:space:]]*}"}"
        trimmed_txt_record="${trimmed_txt_record%"${trimmed_txt_record##*[![:space:]]}"}"

        # Make the API call and save its response
        resp=$(curl --request POST \
                    --url "${API_BASE}${API_VERSION}${API_ENDPOINT}" \
                    --header "Content-Type: application/json" \
                    --header "Authorization: Bearer ${API_KEY}" \
                    --data "{
                      \"content\": \"${trimmed_txt_record}\",
                      \"name\": \"${ACME}.${SUBDOMAIN}\",
                      \"type\": \"TXT\",
                      \"comment\": \"Domain verification record\",
                      \"ttl\": 1
                    }")
	record_id=$(echo "$resp" | awk -F'"id":"' '{print $2}' | awk -F'"' '{print $1}')
    fi
    # Decrement the line tracker so it will only equal 0 two lines after the certbot output that says "with the following value:"
    (( txt_record_line-- ))

# This line is kinda magic. It sets a sleep timer after which echo simulates the user pressing the "Enter" key. That key press is piped to certbot so it can continue confirming the TXT record is created
done < <((sleep $SLEEP_TIME; echo) | certbot certonly --force-renewal --manual --preferred-challenges dns -d "${SUBDOMAIN}.${DOMAIN}.${TLD}" --agree-tos --email "${EMAIL}" 2>&1)

# Delete the TXT record because it won't be needed again
resp=$(curl --request DELETE \
            --url "${API_BASE}${API_VERSION}${API_ENDPOINT}/${record_id}" \
            --header "Content-Type: application/json" \
            --header "Authorization: Bearer ${API_KEY}")

# Make sure unifi account can access the directories it will need

for dir in /etc "${LE_BASE}" "${LE_ARCHIVE_BASE}" "${LE_ARCHIVE_LOCATION}" "${LE_LIVE_BASE}" "${LE_LIVE_LOCATION}"; do
    chmod o+x "$dir"
done

chmod o+wx "${CORE_BASE}"

# Change file ownership

chown unifi "${LE_FULL_CHAIN}"

chown unifi "${LE_PRIV_KEY}"

chown unifi "${CRT_FILE}"

chown unifi "${KEY_FILE}"

/sbin/reboot