#!/usr/bin/env bash
# Runs ON THE VM as root. Syncs the compose stack into /opt/ghost, refreshes .env from
# Secret Manager, then pulls and restarts the containers.
#
# Usage: sudo scripts/deploy.sh [bundle_dir]   (default: /tmp/ghost-deploy)
set -euo pipefail

SRC="${1:-/tmp/ghost-deploy}"
DEST="/opt/ghost"
SECRET_NAME="${SECRET_NAME:-ghost-env}"

if [[ $EUID -ne 0 ]]; then
  echo "run as root (sudo)" >&2
  exit 1
fi

if ! mountpoint -q /mnt/ghost-data; then
  echo "/mnt/ghost-data is not mounted; refusing to start Ghost on the boot disk" >&2
  exit 1
fi

mkdir -p "$DEST"
rsync -a --delete --exclude '.env' --exclude 'data/' "$SRC/ghost/" "$DEST/"

"$SRC/scripts/fetch-env.sh" "$SECRET_NAME" > "$DEST/.env.new"
chmod 600 "$DEST/.env.new"
mv "$DEST/.env.new" "$DEST/.env"

cd "$DEST"
docker compose pull --quiet
docker compose up -d --remove-orphans
docker image prune -f >/dev/null

echo "Deployed. Containers:"
docker compose ps
