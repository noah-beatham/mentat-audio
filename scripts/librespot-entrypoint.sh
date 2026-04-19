#!/bin/bash
set -e

# Create the FIFO if it doesn't already exist
if [ ! -p "$PIPE_PATH" ]; then
    echo "[librespot] Creating FIFO at $PIPE_PATH"
    mkfifo "$PIPE_PATH"
    chmod 666 "$PIPE_PATH"
fi

chmod +x /scripts/*.sh

echo "[librespot] Starting as \"$DEVICE_NAME\" -> $PIPE_PATH"

exec librespot \
    --name "$DEVICE_NAME" \
    --backend pipe \
    --device "$PIPE_PATH" \
    --bitrate 320 \
    --onevent "$EVENT_SCRIPT" \
    --disable-audio-cache \
    --initial-volume 100
