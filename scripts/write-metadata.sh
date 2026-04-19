#!/bin/bash
# Write Shairport Sync XML metadata to an OwnTone metadata pipe.
# Usage: write-metadata.sh <metadata_pipe_path>
#
# Reads NAME, ARTISTS, ALBUM, COVERS from environment (set by librespot onevent).

METADATA_PIPE="$1"

[ -p "$METADATA_PIPE" ] || exit 0  # bail if pipe doesn't exist

# Encode a single DMAP metadata item as Shairport Sync XML
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

# Build the full metadata block
{
    # ssnc/mdst — metadata start
    printf '<item><type>73736e63</type><code>6d647374</code><length>0</length></item>\n'

    # core/minm — track title
    [ -n "$NAME" ]    && write_item "636f7265" "6d696e6d" "$NAME"

    # core/asar — artist (first line only, ARTISTS may be newline-separated)
    ARTIST="${ARTISTS%%$'\n'*}"
    [ -n "$ARTIST" ]  && write_item "636f7265" "61736172" "$ARTIST"

    # core/asal — album
    [ -n "$ALBUM" ]   && write_item "636f7265" "6173616c" "$ALBUM"

    # ssnc/mden — metadata end
    printf '<item><type>73736e63</type><code>6d64656e</code><length>0</length></item>\n'

} | timeout 3 tee "$METADATA_PIPE" > /dev/null || true
