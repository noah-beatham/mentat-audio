#!/bin/bash
set -e

REPO_DIR="/srv/ledger/app"
AUDIO_DIR="/srv/audio"

echo "==> Pulling latest code"
cd "$REPO_DIR" && git pull origin main

echo "==> Syncing audio files to $AUDIO_DIR"
rsync -av --delete "$REPO_DIR/audio/" "$AUDIO_DIR/"

echo "==> Making scripts executable"
chmod +x "$AUDIO_DIR/scripts/"*.sh

echo "==> Building and starting containers"
cd "$AUDIO_DIR"
docker compose up -d --build

echo ""
echo "==> Done. Useful commands:"
echo "  Check speaker names:  curl -s http://localhost:3689/api/outputs | jq '.outputs[] | .name'"
echo "  OwnTone logs:         docker logs audio-owntone -f"
echo "  Living Room logs:     docker logs audio-lr -f"
echo "  All logs:             docker logs audio-all -f"
