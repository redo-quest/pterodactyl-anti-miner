#!/bin/bash

apt-get update
apt-get install -y jq curl


cat << 'EOF' > /home/container/run.sh
#!/bin/bash

PTERODACTYL_API_KEY="$PTERODACTYL_API_KEY"
PANEL_URL="$PANEL_URL"
SCAN_INTERVAL="$SCAN_INTERVAL"

scan_and_suspend_miners() {
    servers=$(curl -s -X GET "$PANEL_URL/api/application/servers" \
              -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
              -H "Content-Type: application/json")

    for server_id in $(echo "$servers" | jq -r '.data[].attributes.id'); do
        server_details=$(curl -s -X GET "$PANEL_URL/api/application/servers/$server_id" \
                         -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
                         -H "Content-Type: application/json")

        if [[ $(echo "$server_details" | grep -i "mining_keyword") ]]; then
            echo "Miner detected on server ID: $server_id. Suspending..."
            curl -s -X POST "$PANEL_URL/api/application/servers/$server_id/suspend" \
                 -H "Authorization: Bearer $PTERODACTYL_API_KEY" \
                 -H "Content-Type: application/json"
            echo "Server $server_id suspended."
        else
            echo "No mining activity detected on server ID: $server_id."
        fi
    done
}

while true; do
    scan_and_suspend_miners
    echo "Sleeping for $SCAN_INTERVAL seconds..."
    sleep $SCAN_INTERVAL
done
EOF

chmod +x /home/container/scan_and_suspend_miners.sh
