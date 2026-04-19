#!/bin/bash
# Shared helper: enable speakers matching PATTERN, disable everything else.
# Usage: set-speakers.sh "apple tv|kitchen"
#
# OwnTone discovers AirPlay speakers by their advertised mDNS name.
# To see what names OwnTone found, run:
#   curl -s http://localhost:3689/api/outputs | jq '.outputs[] | {name,id}'

OWNTONE="http://127.0.0.1:3689"
PATTERN="$1"

# Wait for OwnTone to be ready (called at play time so should already be up)
for i in $(seq 1 10); do
    curl -sf "$OWNTONE/api/config" > /dev/null 2>&1 && break
    sleep 1
done

OUTPUTS=$(curl -sf "$OWNTONE/api/outputs" 2>/dev/null) || {
    echo "[event] Could not reach OwnTone API" >&2
    exit 1
}

echo "$OUTPUTS" | jq -r '.outputs[] | "\(.id)|\(.name)"' | \
while IFS='|' read -r id name; do
    if echo "$name" | grep -qiE "$PATTERN"; then
        curl -sf -X PUT "$OWNTONE/api/outputs/$id" \
            -H "Content-Type: application/json" \
            -d '{"selected": true}' > /dev/null
        echo "[event] Enabled:  $name"
    else
        curl -sf -X PUT "$OWNTONE/api/outputs/$id" \
            -H "Content-Type: application/json" \
            -d '{"selected": false}' > /dev/null
        echo "[event] Disabled: $name"
    fi
done
