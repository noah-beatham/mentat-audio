#!/bin/bash
# Event handler for "Mentat - Living Room"
# Speakers: Apple TV (10.0.0.41) + Kitchen A100 (10.0.0.180)
#
# OwnTone names these speakers by their AirPlay advertisement name.
# If speaker selection isn't working, check the actual names with:
#   curl -s http://localhost:3689/api/outputs | jq '.outputs[] | .name'
# Then update LR_PATTERN below to match.

LR_PATTERN="^judge$|^kitchen$"
METADATA_PIPE="/srv/pipes/lr.pipe.metadata"

OWNTONE="http://127.0.0.1:3689"

case "$PLAYER_EVENT" in
    playing)
        echo "[lr] playing — selecting Living Room speakers"
        /scripts/set-speakers.sh "$LR_PATTERN"
        # Write track state for metadata-daemon to pick up
        printf 'NAME=%s\nARTIST=%s\nALBUM=%s\nCOVER=%s\nTRACK_ID=%s\n' \
            "${NAME}" "${ARTISTS%%$'\n'*}" "${ALBUM}" "${COVERS%%$'\n'*}" "${TRACK_ID}" \
            > /tmp/nowplaying_lr.pipe
        ;;
    stopped)
        echo "[lr] stopped"
        curl -sf -X PUT "$OWNTONE/api/player/stop" > /dev/null || true
        ;;
    paused)
        echo "[lr] paused"
        curl -sf -X PUT "$OWNTONE/api/player/pause" > /dev/null || true
        ;;
esac
