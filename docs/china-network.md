# 国内网络与镜像备忘

上游：[melgarafael/DeskcommCRM](https://github.com/melgarafael/DeskcommCRM)  
生产镜像命名空间：`ghcr.io/melgarafael/`（`deskcommcrm` / `deskcomm-worker` / `deskcomm-scheduler`）  
WhatsApp 引擎镜像：Docker Hub `devlikeapro/waha`（上游 compose 有钉死 tag）

## 1. 拉 GHCR

安装器默认 `pull`：

- `ghcr.io/melgarafael/deskcommcrm:<ver>`
- `ghcr.io/melgarafael/deskcomm-worker:<ver>`
- `ghcr.io/melgarafael/deskcomm-scheduler:<ver>`

本仓 `scripts/probe-ghcr.sh` **不需要 Docker**，可先确认 registry 是否从你的网络可达。

常见失败：

| 现象 | 处理 |
|------|------|
| `dial tcp … ghcr.io:443` / timeout | VPS 走可访问 GHCR 的线路；或 HTTP/SOCKS 代理给 Docker |
| `403` / `denied` | 公开包一般可匿名；若被策略挡，`docker login ghcr.io` 后再 pull |
| pull 失败后偷偷本地 build | 上游 **故意** 不在 `docker-compose.prod.yml` 给 app 配 `build:`，避免 DNS 故障时 VPS 上 `next build` OOM。修好网络再 `update.sh` / `compose pull` |

钉版本示例见 `deploy-snippets/images.env`。`stable` ≈ 最新 release；`latest` = **main 尖端**，勿用于正式客户机。

### Docker 走代理（示意）

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf >/dev/null <<'EOT'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.1"
EOT
sudo systemctl daemon-reload && sudo systemctl restart docker
```

换成本机代理地址。中转镜像仓库亦可，自行改 `APP_IMAGE=你的镜像站/...`。

## 2. Docker Hub（WAHA）

生产 / 本地栈都会拉 `devlikeapro/waha`。Hub 限流或超时：

- 登录 Docker Hub 提高匿名限流
- 或配置 registry mirror（各云厂商文档不一，以你 VPS 供应商为准）

上游本地 compose 曾钉 `devlikeapro/waha:latest-2026.7.2`，且 **该 tag 实测仅 linux/amd64**；Apple Silicon / ARM VPS 生产路径由安装器选官方 arm64 NOWEB 变体，勿照抄 amd64-only 钉死到 ARM 主机。

## 3. Git clone

`git clone https://github.com/melgarafael/DeskcommCRM.git` 若慢：

```bash
# 加深浅克隆 + 指定 release
git clone --depth 1 --branch v1.97.0 https://github.com/melgarafael/DeskcommCRM.git
# 或 GHPROXY / 自建镜像（自行评估信任）
```

本仓：`./scripts/clone-upstream.sh`。

## 4. Supabase

- 免费档项目建在就近区域（上游巴西社区常用 `sa-east-1`；国内延迟可能偏高，可试新加坡等，以控制台可选为准）
- **必须用 Session pooler 连接串**；Direct connection 常为 IPv6-only，国内 / 多数 VPS IPv4 会连不上——这是上游反复强调的坑
- 可选 `SUPABASE_ACCESS_TOKEN` 让 `install.sh` 自动建项目并探测 pooler

## 5. AI 与 WhatsApp

- AI：OpenRouter / Anthropic / OpenAI；国内机器访问官方 API 常需代理或改用 OpenRouter 可达端点
- WhatsApp：QR（WAHA）依赖 VPS 出网稳定；号码与封号风险自负，语音通话 profile 上游默认关闭

## 6. 域名与证书

`install.sh` 默认 Caddy + Let’s Encrypt。域名需解析到 VPS。  
若用国内备案域名 / 反向代理面板，按上游「已有 Traefik」路径设 `REVERSE_PROXY=traefik`，不要强行再起 Caddy 抢 80/443。
