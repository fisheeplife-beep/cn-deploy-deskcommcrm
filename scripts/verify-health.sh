#!/usr/bin/env bash
# Verify a running DeskcommCRM instance health endpoint.
# Usage: BASE_URL=https://crm.example.com ./scripts/verify-health.sh
# Local/dev default: http://127.0.0.1:3000
set -euo pipefail

BASE="${BASE_URL:-http://127.0.0.1:3000}"
BASE="${BASE%/}"
URL="${BASE}/api/v1/health"

echo "GET $URL"
body=$(curl -fsS --max-time 20 "$URL" || true)
if [[ -z "$body" ]]; then
  echo "No response. If you are on the VPS, try inside the app container:"
  echo "  docker compose -f docker-compose.prod.yml exec -T app node -e \"fetch('http://127.0.0.1:3000/api/v1/health').then(r=>r.text()).then(console.log)\""
  echo "Or: bash hostgator-setup-kit/healthcheck.sh"
  exit 1
fi
echo "$body"
if echo "$body" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"'; then
  echo "OK: status=ok"
else
  echo "WARN: body returned but status is not ok (WAHA/Redis/Supabase may be degraded)"
  exit 2
fi
