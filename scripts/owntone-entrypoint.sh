#!/bin/bash
set -e

# Ensure pipes directory exists before OwnTone scans it
mkdir -p /srv/pipes

exec owntone -f -c /etc/owntone/owntone.conf
