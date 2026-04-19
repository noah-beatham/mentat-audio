#!/bin/bash
# Write Shairport Sync XML metadata to an OwnTone metadata pipe.
# Usage: write-metadata.sh <metadata_pipe_path>
#
# Reads NAME, ARTISTS, ALBUM, COVERS from environment (set by librespot onevent).
# Fetches cover art from the URL librespot provides and embeds it as PICT data
# so OwnTone can forward it to Apple TV via AirPlay SET_PARAMETER.

METADATA_PIPE="$1"

[ -p "$METADATA_PIPE" ] || exit 0  # bail if pipe doesn't exist

# Encode a DMAP metadata item as Shairport Sync XML
write_item() {
    local type_hex="$1"
    local code_hex="$2"
    local data="$3"
    local length="${#data}"
    local b64
    b64=$(printf '%s' "$data" | base64 -w 0)
    printf '<item><type>%s</type><code>%s</code><length>%d</length><data encoding="base64">%s</data></item>\n' \
        "$type_hex" "$code_hex" "$length" "$b64"
}

# Build the full metadata block in a temp file, then pipe it atomically
TMPFILE=$(mktemp)

# ssnc/mdst — metadata start
printf '<item><type>73736e63</type><code>6d647374</code><length>0</length></item>\n' >> "$TMPFILE"

# core/minm — track title
[ -n "$NAME" ]   && write_item "636f7265" "6d696e6d" "$NAME"   >> "$TMPFILE"

# core/asar — artist (ARTISTS may be newline-separated; take first)
ARTIST="${ARTISTS%%$'\n'*}"
[ -n "$ARTIST" ] && write_item "636f7265" "61736172" "$ARTIST" >> "$TMPFILE"

# core/asal — album
[ -n "$ALBUM" ]  && write_item "636f7265" "6173616c" "$ALBUM"  >> "$TMPFILE"

# core/PICT — cover artwork (fetch from Spotify CDN URL librespot provides)
COVER_URL="${COVERS%%$'\n'*}"  # first URL if multiple
if [ -n "$COVER_URL" ]; then
    IMG_DATA=$(curl -sf --max-time 5 "$COVER_URL" | base64 -w 0)
    if [ -n "$IMG_DATA" ]; then
        IMG_LEN=$(printf '%s' "$IMG_DATA" | base64 -d | wc -c)
        printf '<item><type>636f7265</type><code>50494354</code><length>%d</length><data encoding="base64">%s</data></item>\n' \
            "$IMG_LEN" "$IMG_DATA" >> "$TMPFILE"
    fi
fi

# ssnc/mden — metadata end
printf '<item><type>73736e63</type><code>6d64656e</code><length>0</length></item>\n' >> "$TMPFILE"

# Write to the metadata pipe with a timeout so we never block the event handler
timeout 5 tee "$METADATA_PIPE" < "$TMPFILE" > /dev/null || true

rm -f "$TMPFILE"
