#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  printf '%s\n' 'DATABASE_URL is required' >&2
  exit 2
fi

output="${1:-backup.dump}"
umask 077
pg_dump --format=custom --file="$output" --dbname="$DATABASE_URL"
printf 'backup_created=%s\n' "$output"
