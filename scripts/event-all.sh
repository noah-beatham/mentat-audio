#!/bin/bash
# Event handler for "Mentat - All"
# Speakers: Apple TV + Kitchen A100 + PC Ray + Bedroom L + Bedroom R
#
# OwnTone names these speakers by their AirPlay advertisement name.
# If speaker selection isn't working, check the actual names with:
#   curl -s http://localhost:3689/api/outputs | jq '.outputs[] | .name'
# Then update ALL_PATTERN below to match.
#
# Sonos room names are set in the Sonos app — adjust the pattern
# to match whatever your rooms are called there.

ALL_PATTERN="^judge$|^kitchen$|^pc$|^bedroom$"
METADATA_PIPE="/srv/pipes/all.pipe.metadata"

OWNTONE="http://127.0.0.1:3689"

case "$PLAYER_EVENT" in
    playing)
        echo "[all] playing — selecting all speakers"
        /scripts/set-speakers.sh "$ALL_PATTERN"
        # Write track state for metadata-daemon to pick up
        printf 'NAME=%s\nARTIST=%s\nALBUM=%s\nCOVER=%s\nTRACK_ID=%s\n' \
            "${NAME}" "${ARTISTS%%$'\n'*}" "${ALBUM}" "${COVERS%%$'\n'*}" "${TRACK_ID}" \
            > /tmp/nowplaying_all.pipe
        ;;
    stopped)
        echo "[all] stopped"
        curl -sf -X PUT "$OWNTONE/api/player/stop" > /dev/null || true
        ;;
    paused)
        echo "[all] paused"
        curl -sf -X PUT "$OWNTONE/api/player/pause" > /dev/null || true
        ;;
esac
