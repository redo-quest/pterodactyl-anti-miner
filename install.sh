#!/bin/bash

apt-get update
apt-get install -y jq curl

# Create the script
cat << 'EOF' > /home/container/run.sh
#!/bin/bash

PTERODACTYL_API_KEY="$PTERODACTYL_API_KEY"
PANEL_URL="$PANEL_URL"
SCAN_INTERVAL="$SCAN_INTERVAL"
MINING_KEYWORDS="$MINING_KEYWORDS"

IFS=',' read -r -a keywords_array <<< "$MINING_KEYWORDS"

run() {
    servers=$(curl -s -X GET "$PANEL_URL/api/application/servers" \
              -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
              -H "Content-Type: application/json")

    for server_id in $(echo "$servers" | jq -r '.data[].attributes.id'); do
        server_details=$(curl -s -X GET "$PANEL_URL/api/application/servers/$server_id" \
                         -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
                         -H "Content-Type: application/json")

        for keyword in "${keywords_array[@]}"; do
            if [[ $(echo "$server_details" | grep -i "$keyword") ]]; then
                echo "Miner detected on server ID: $server_id with keyword: $keyword. Suspending..."
                curl -s -X POST "$PANEL_URL/api/application/servers/$server_id/suspend" \
                     -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
                     -H "Content-Type: application/json"
                echo "Server $server_id suspended."
                break
            else
                echo "No mining activity detected on server ID: $server_id for keyword: $keyword."
            fi
        done
    done
}

while true; do
    run
    echo "Sleeping for $SCAN_INTERVAL seconds..."
    sleep $SCAN_INTERVAL
done
EOF

chmod +x /home/container/install.sh
