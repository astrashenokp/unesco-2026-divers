#!/usr/bin/env bash
set -euo pipefail

if [[ "${ALLOW_DESTRUCTIVE_RESTORE:-}" != "1" ]]; then
  printf '%s\n' 'Set ALLOW_DESTRUCTIVE_RESTORE=1 for an isolated restore target' >&2
  exit 2
fi
if [[ -z "${RESTORE_DATABASE_URL:-}" || -z "${1:-}" ]]; then
  printf '%s\n' 'RESTORE_DATABASE_URL and a backup path are required' >&2
  exit 2
fi

pg_restore --clean --if-exists --no-owner --dbname="$RESTORE_DATABASE_URL" "$1"
printf 'restore_completed=%s\n' "$1"
