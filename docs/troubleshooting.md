# 常见报错与处理（DeskcommCRM）

更全的运维手册在上游（多为巴西葡语）：`hostgator-setup-kit/`、`docs/runbooks/`、`docs/ATUALIZANDO.md`。

## 安装卡住 / 密钥校验失败

**现象**：交互安装拒绝 API Key 或 Supabase 字段。  
**处理**：对照 `.env.hostgator.example`；Supabase 四项（URL / anon / service_role / **pooler** DB URL）勿混用 legacy JWT 与新 key 格式。先 `export SUPABASE_ACCESS_TOKEN=...` 让安装器代填。

## `supabase db push` 后库是空的

**原因**：开发文档写明 migrations `0001–0009` 等是 stub；真 schema 在 `supabase/baseline.sql`。  
**处理**：自托管与本地一律对 pooler/DB 执行 baseline（`install.sh` 会做）。不要只用 `db push` 当安装。

## 应用 502 / Caddy 起不来

**常见**：80/443 已被 Coolify/Traefik/Hostinger 面板占用。  
**处理**：设 `REVERSE_PROXY=traefik`（或按面板文档），用上游 `docker-compose.prod.yml` + `docker-compose.traefik.yml`。Hostinger `--network host` 场景安装器会**提问**，`--yes` 模式需你预写好变量。

## GHCR pull 失败后机器变卡 / OOM

上游刻意避免「pull 失败就地编译 Next」。修好 DNS/代理后：

```bash
bash hostgator-setup-kit/update.sh
# 或
docker compose -f docker-compose.prod.yml --env-file .env pull
docker compose -f docker-compose.prod.yml --env-file .env up -d
```

## `/api/v1/health` 非 ok

JSON 里会标 WAHA / Redis / Supabase 等子系统。TCP 健康检查仍可能绿（Caddy 不因次要依赖黑掉整站）。跑：

```bash
bash hostgator-setup-kit/healthcheck.sh
```

## 自动化规则不跑

`event_log` 靠 cron drain。确认 `install.sh`/`update.sh` 装过自动化 cron；否则规则只入库不执行。

## 屏幕上没有「更新」按钮

更新代理 cron（`hostgator-setup-kit/agent.sh` 每 5 分钟）未装或失败。看 `.update-agent.log`，重跑 `update.sh`。

## WhatsApp 一直「连接中」

- WAHA 会话未 `WHATSAPP_RESTART_ALL_SESSIONS` / 容器重启后 STOPPED  
- 出网被墙或 UDP/WebSocket 不稳  
- 扫错号 / 多设备限制  

查 `docker compose … logs waha`，必要时清 session volume（会掉线重扫 QR）。

## ARM（Oracle Ampere 等）

上游支持 arm64 镜像与 WAHA NOWEB arm 变体。勿把仅 amd64 的 Hub tag 硬写进生产 `.env`。详见上游 `docs/runbooks/oracle-arm64.md`。

## 本地 `pnpm dev` Node 版本

`.nvmrc` = **22**。Node 20 会不符合。生产路径**不需要**在 VPS 装 Node。
