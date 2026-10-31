#!/usr/bin/env bash
# DeskcommCRM CN preflight — checks host readiness before VPS install.
set -euo pipefail

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
say "=== DeskcommCRM CN preflight ==="
say ""

# Docker
if command -v docker >/dev/null 2>&1; then
  pass "Docker: $(docker --version 2>/dev/null | head -1)"
  if docker compose version >/dev/null 2>&1; then
    pass "Compose V2: $(docker compose version --short 2>/dev/null || docker compose version | head -1)"
  else
    fail "docker compose V2 missing (install.sh needs it)"
  fi
else
  fail "Docker not found — VPS path requires Docker; install.sh can install it when run as root"
fi

# git / curl / openssl (install.sh host deps)
for bin in git curl openssl; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "$bin present"
  else
    fail "$bin missing (install.sh expects it on the VPS)"
  fi
done

# RAM hint
if [[ -r /proc/meminfo ]]; then
  mb=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
  if [[ "$mb" -ge 3500 ]]; then
    pass "RAM ~${mb} MiB (upstream recommends ~4 GB)"
  elif [[ "$mb" -ge 1800 ]]; then
    warn_ "RAM ~${mb} MiB — stack may boot, WAHA+app will be tight; add swap"
  else
    fail "RAM ~${mb} MiB — too low for production stack"
  fi
fi

# Arch
arch=$(uname -m)
case "$arch" in
  x86_64|amd64|aarch64|arm64) pass "CPU arch $arch (amd64/arm64 images published)" ;;
  *) warn_ "Unusual arch $arch — check GHCR platform manifests" ;;
esac

# GHCR reachability (HTTP probe, no docker needed)
if [[ -x "$ROOT/scripts/probe-ghcr.sh" ]]; then
  if "$ROOT/scripts/probe-ghcr.sh" >/tmp/cn-deskcomm-ghcr.out 2>&1; then
    pass "GHCR manifests reachable (deskcommcrm/worker/scheduler :stable)"
  else
    fail "GHCR probe failed — see docs/china-network.md (proxy / mirror)"
    sed -n '1,20p' /tmp/cn-deskcomm-ghcr.out || true
  fi
fi

# Domain DNS optional
if [[ -n "${DOMAIN:-}" ]]; then
  if command -v getent >/dev/null 2>&1; then
    if getent ahostsv4 "$DOMAIN" >/dev/null 2>&1; then
      pass "DOMAIN=$DOMAIN resolves (A/AAAA via getent)"
    else
      warn_ "DOMAIN=$DOMAIN did not resolve yet — point A record at this VPS before HTTPS"
    fi
  fi
else
  say "   (set DOMAIN=crm.example.com to check DNS)"
fi

# Ports 80/443 hint
if command -v ss >/dev/null 2>&1; then
  if ss -lnt | grep -Eq ':80\s|:443\s'; then
    warn_ "Something already listens on 80/443 — install.sh may switch to Traefik/NPM overlay"
  else
    pass "Ports 80/443 look free (or ss empty)"
  fi
fi

say ""
say "Summary: ok=$ok warn=$warn bad=$bad"
[[ "$bad" -eq 0 ]] || exit 1
