#!/usr/bin/env bash
# Shallow-clone upstream DeskcommCRM at a release tag (default v1.97.0).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${DESKCOMM_TAG:-v1.97.0}"
DEST="${DESKCOMM_SRC_DIR:-$ROOT/data/upstream-DeskcommCRM}"
URL="${DESKCOMM_UPSTREAM_URL:-https://github.com/melgarafael/DeskcommCRM.git}"

mkdir -p "$(dirname "$DEST")"
if [[ -d "$DEST/.git" ]]; then
  echo "Existing clone: $DEST"
  git -C "$DEST" fetch --tags --depth 1 origin "refs/tags/${TAG}:refs/tags/${TAG}" 2>/dev/null || \
    git -C "$DEST" fetch --depth 1 origin tag "$TAG" || true
  git -C "$DEST" checkout -f "$TAG"
else
  git clone --depth 1 --branch "$TAG" "$URL" "$DEST"
fi

echo "Checked out $TAG → $DEST"
echo "Next on a VPS with Docker:"
echo "  cd $DEST && bash hostgator-setup-kit/install.sh"
