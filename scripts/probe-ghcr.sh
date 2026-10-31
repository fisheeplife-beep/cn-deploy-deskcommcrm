#!/usr/bin/env bash
# Probe public GHCR OCI indexes for DeskcommCRM images (no Docker required).
set -euo pipefail

TAG="${DESKCOMM_IMAGE_TAG:-stable}"
IMGS=(
  "melgarafael/deskcommcrm"
  "melgarafael/deskcomm-worker"
  "melgarafael/deskcomm-scheduler"
)

probe() {
  local name="$1" tag="$2"
  local tok code
  tok=$(curl -fsS "https://ghcr.io/token?service=ghcr.io&scope=repository:${name}:pull" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
  code=$(curl -sS -o /tmp/cn-deskcomm-manifest.json -w '%{http_code}' \
    -H "Authorization: Bearer ${tok}" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json" \
    "https://ghcr.io/v2/${name}/manifests/${tag}")
  if [[ "$code" != "200" ]]; then
    echo "FAIL ghcr.io/${name}:${tag} HTTP $code" >&2
    return 1
  fi
  python3 - "$name" "$tag" <<'PY'
import json,sys
name,tag=sys.argv[1],sys.argv[2]
idx=json.load(open("/tmp/cn-deskcomm-manifest.json"))
plats=[]
for m in idx.get("manifests") or []:
  p=m.get("platform") or {}
  if p.get("os") and p.get("os")!="unknown":
    plats.append(f"{p.get('os')}/{p.get('architecture')}")
print(f"OK ghcr.io/{name}:{tag} plats={','.join(plats) or 'n/a'}")
PY
}

for img in "${IMGS[@]}"; do
  probe "$img" "$TAG"
done
