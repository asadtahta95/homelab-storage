#!/usr/bin/env bash
# Generic backup template: Immich DB dump + data archive with borg.
# Copy to backup.sh, adjust the ALL_CAPS placeholders, add to cron.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BORG_REPO="/BACKUP_DISK/borg-homelab"     # e.g. /srv/backup-disk/borg-homelab
export BORG_PASSPHRASE="CHANGE_ME"        # store in a 600 file instead
DUMP_DIR="$REPO_DIR/.backups"
STORAGE_PATH="${STORAGE_PATH:-/srv/storage}"

mkdir -p "$DUMP_DIR"

echo "== $(date '+%F %T') backup start =="

# 1. Immich database dump (skipped if stack not installed)
if docker ps --format '{{.Names}}' | grep -qx immich_postgres; then
  DB_USER="$(grep -E '^DB_USERNAME=' "$REPO_DIR/immich/.env" | cut -d= -f2)"
  DB_NAME="$(grep -E '^DB_DATABASE_NAME=' "$REPO_DIR/immich/.env" | cut -d= -f2)"
  docker exec immich_postgres pg_dump -U "$DB_USER" "$DB_NAME" \
    | gzip > "$DUMP_DIR/immich.sql.gz"
  echo "dump immich: $(du -h "$DUMP_DIR/immich.sql.gz" | cut -f1)"
fi

# 2. Borg archive (init the repo once: borg init --encryption=repokey-blake2)
# shellcheck disable=SC2029
borg create --stats \
  --exclude '*/filebrowser/data/tmp' \
  --exclude '*/immich/postgres' \
  ::'{hostname}-{now:%Y%m%d-%H%M}' \
  "$REPO_DIR/filebrowser/data/config.yaml" \
  "$REPO_DIR/filebrowser/docker-compose.yml" \
  "$REPO_DIR/immich/docker-compose.yml" \
  "$DUMP_DIR" \
  "$STORAGE_PATH" \
  && borg prune --keep-weekly=8 --keep-monthly=6 \
  && borg compact

echo "== $(date '+%F %T') backup done =="
