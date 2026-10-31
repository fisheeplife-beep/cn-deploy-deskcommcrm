# cn-deploy-deskcommcrm

> **Series index:** [cn-deploy](https://github.com/fisheeplife-beep/cn-deploy) — Chinese follow-along deployment companions.

Chinese, follow-along **deployment companion** for [melgarafael/DeskcommCRM](https://github.com/melgarafael/DeskcommCRM) (MIT) — not an official fork, and not a verbatim copy of upstream docs.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

### What you get

- Preflight + **GHCR probe** (no Docker required) for `deskcommcrm` / `deskcomm-worker` / `deskcomm-scheduler`
- Clone helpers pinned to upstream **release tags** (e.g. `v1.97.0`)
- Condensed `.env.example` + `deploy-snippets/images.env` for the official `hostgator-setup-kit/install.sh`
- China network notes (GHCR, Docker Hub / WAHA, Supabase Session pooler, proxies)

### Verification snapshot (author box, 2026-10-31 Asia/Shanghai)

| Path | Status |
|------|--------|
| Upstream `melgarafael/DeskcommCRM` @ `v1.97.0` tree (install kit, prod compose, baseline.sql) | **Confirmed** |
| GHCR OCI indexes `:stable` / `:1.97.0` (amd64+arm64) for app/worker/scheduler | **Verified** (HTTP); see `examples/ghcr-probe.txt` |
| Full VPS `install.sh` + HTTPS + WhatsApp QR | **Not run** (no Docker / domain / keys on author box) |
| Local `pnpm dev` (Node 22) | **Not run** (box has Node 20) |

### Quick links

```bash
./scripts/probe-ghcr.sh
./scripts/preflight.sh
DESKCOMM_TAG=v1.97.0 ./scripts/clone-upstream.sh
# On a VPS with Docker + filled .env:
#   bash data/upstream-DeskcommCRM/hostgator-setup-kit/install.sh
BASE_URL=https://your.domain ./scripts/verify-health.sh
```

Upstream: https://github.com/melgarafael/DeskcommCRM · https://deskcomm.com.br  
License for this companion: [MIT](./LICENSE)
