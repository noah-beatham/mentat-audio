#!/bin/bash
# Metadata pipe daemon — runs in background inside the librespot container.
#
# Holds the write-end of <pipe>.metadata open so OwnTone keeps its read-end
# open. When the event script drops a new track state file, writes fresh
# Shairport Sync XML to the pipe so OwnTone forwards it over AirPlay.
#
# Usage: metadata-daemon.sh /srv/pipes/lr.pipe

AUDIO_PIPE="$1"
METADATA_PIPE="${AUDIO_PIPE}.metadata"
STATE_FILE="/tmp/nowplaying_$(basename "$AUDIO_PIPE")"

write_item() {
    local type_hex="$1" code_hex="$2" data="$3"
    local len b64
    len=$(printf '%s' "$data" | wc -c)
    b64=$(printf '%s' "$data" | base64 -w 0)
    printf '<item><type>%s</type><code>%s</code><length>%d</length><data encoding="base64">%s</data></item>' \
        "$type_hex" "$code_hex" "$len" "$b64"
}

send_metadata() {
    local fd="$1"
    # Read state written by event script
    local name artist album cover_url
    name=$(   grep '^NAME='    "$STATE_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\n')
    artist=$(  grep '^ARTIST='  "$STATE_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\n')
    album=$(   grep '^ALBUM='   "$STATE_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\n')
    cover_url=$(grep '^COVER='  "$STATE_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\n')

    {
        # ssnc/mdst — start
        printf '<item><type>73736e63</type><code>6d647374</code><length>0</length></item>'
        [ -n "$name" ]   && write_item "636f7265" "6d696e6d" "$name"
        [ -n "$artist" ] && write_item "636f7265" "61736172" "$artist"
        [ -n "$album" ]  && write_item "636f7265" "6173616c" "$album"
        # Artwork: fetch from Spotify CDN and embed as PICT
        if [ -n "$cover_url" ]; then
            local img b64img imglen
            img=$(curl -sf --max-time 5 "$cover_url")
            if [ -n "$img" ]; then
                b64img=$(printf '%s' "$img" | base64 -w 0)
                imglen=$(printf '%s' "$img" | wc -c)
                printf '<item><type>636f7265</type><code>50494354</code><length>%d</length><data encoding="base64">%s</data></item>' \
                    "$imglen" "$b64img"
            fi
        fi
        # ssnc/mden — end
        printf '<item><type>73736e63</type><code>6d64656e</code><length>0</length></item>'
    } >&"$fd" 2>/dev/null
}

echo "[metadata-daemon] Starting for $METADATA_PIPE"

LAST_STATE=""

while true; do
    # Open write-end — blocks until OwnTone opens the read-end
    exec 3>"$METADATA_PIPE" 2>/dev/null
    if [ $? -ne 0 ]; then
        sleep 2
        continue
    fi

    echo "[metadata-daemon] Connected"

    # If we already have track state, send it immediately on connect
    if [ -f "$STATE_FILE" ]; then
        send_metadata 3
        LAST_STATE=$(stat -c %Y "$STATE_FILE" 2>/dev/null)
    fi

    # Watch for state changes while the pipe stays open
    while true; do
        CURRENT_STATE=$(stat -c %Y "$STATE_FILE" 2>/dev/null)
        if [ -n "$CURRENT_STATE" ] && [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
            send_metadata 3 || break
            LAST_STATE="$CURRENT_STATE"
        fi
        # Heartbeat: check write-end is still alive
        printf '' >&3 2>/dev/null || break
        sleep 1
    done

    exec 3>&-
    echo "[metadata-daemon] Disconnected, reconnecting..."
    sleep 1
done
