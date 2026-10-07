#!/usr/bin/env bash
# Reset the Filebrowser admin password when you are locked out.
# Stops the container briefly (DB must not be locked), sets the user, starts it.
# Usage: sudo ./scripts/reset-admin.sh [username]
set -euo pipefail
cd "$(dirname "$0")/../filebrowser"
USER="${1:-admin}"
docker compose stop filebrowser
docker compose run --rm --no-deps \
  -v ./data:/home/filebrowser/data \
  filebrowser ./filebrowser set -u "$USER" -a -c /home/filebrowser/data/config.yaml
docker compose start filebrowser
echo "Password reset for '$USER'. Start the container log to verify, then login."
