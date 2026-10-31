#!/usr/bin/env bash
# Prepare upstream tree + .env, then hand off to official install.sh.
# Safe to run locally for prep; real install must run ON the VPS as root/sudo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/clone-upstream.sh"
DEST="${DESKCOMM_SRC_DIR:-$ROOT/data/upstream-DeskcommCRM}"

if [[ -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env" "$DEST/.env"
  echo "Copied companion .env → $DEST/.env"
elif [[ -f "$ROOT/.env.example" && ! -f "$DEST/.env" ]]; then
  cp "$ROOT/.env.example" "$DEST/.env"
  echo "Seeded $DEST/.env from companion .env.example — EDIT before --yes"
fi

if [[ "${DESKCOMM_RUN_INSTALL:-0}" == "1" ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker missing; refuse to run install.sh" >&2
    exit 1
  fi
  cd "$DEST"
  if [[ "${DESKCOMM_NONINTERACTIVE:-0}" == "1" ]]; then
    exec bash hostgator-setup-kit/install.sh --yes
  fi
  exec bash hostgator-setup-kit/install.sh
fi

cat <<MSG
Prepared: $DEST

On the VPS (recommended):
  cd $DEST
  bash hostgator-setup-kit/install.sh

Non-interactive (after filling .env):
  DESKCOMM_RUN_INSTALL=1 DESKCOMM_NONINTERACTIVE=1 $0

Or merge image pins:
  cat $ROOT/deploy-snippets/images.env >> $DEST/.env
MSG
