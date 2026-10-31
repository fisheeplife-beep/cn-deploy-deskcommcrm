# DeskcommCRM 国内可跟做部署配套

> **系列索引：** [cn-deploy](https://github.com/fisheeplife-beep/cn-deploy) — 中文可跟做部署配套合集。

> 上游仓库：[melgarafael/DeskcommCRM](https://github.com/melgarafael/DeskcommCRM)（**MIT**）  
> 官网：https://deskcomm.com.br · 英文说明：上游 `README.en.md`  
> 官方安装套件：上游 `hostgator-setup-kit/`（`install.sh` / `update.sh` / `healthcheck.sh`）  
> 本仓性质：**独立中文部署配套**（预检脚本 / 镜像钉 / 国内网络与踩坑），**不是**官方镜像或 fork，也**不会**整页搬运上游 README。

DeskcommCRM 是开源的「WhatsApp + AI 销售 OS」自托管 CRM（Next.js + Supabase + WAHA），对标 Kommo / Intercom 一类聊天成交工具。  
本仓目标：在**国内网络 / 常见 Linux VPS**上，按步骤把生产栈装起来，并事先知道「成功长什么样」与「本仓作者验证到哪一步」。

官方文档主体为**巴西葡萄牙语**（另有 EN/ES README），完整中文跟做资料仍稀缺——这就是本配套存在的理由。

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-10-31，Asia/Shanghai） |
|------|--------------------------------------------------|
| **上游身份与发版** | ✅ **已确认** — 准确上游名 `melgarafael/DeskcommCRM`；最新 release **`v1.97.0`**（当日）；`hostgator-setup-kit/install.sh`、`docker-compose.prod.yml`、`supabase/baseline.sql` 均在 tag 内 |
| **GHCR 三镜像 OCI 索引** | ✅ **已验证（HTTP，无需 Docker）** — `deskcommcrm` / `deskcomm-worker` / `deskcomm-scheduler` 的 `:stable` 与 `:1.97.0` 均为 **HTTP 200**，含 **linux/amd64 + linux/arm64**；`stable` digest 与 `1.97.0` 一致。见 [`examples/ghcr-probe.txt`](./examples/ghcr-probe.txt) |
| **Docker Hub WAHA 钉** | ✅ **标签存在** — `devlikeapro/waha:latest-2026.7.2` Hub API **200**（该 tag 侧车为 **amd64**；生产 ARM 勿照抄） |
| **VPS：`install.sh` 全量起栈 + HTTPS + 登录** | ⚠️ **未在本机跑通** — 验证机**无 Docker**、无公网域名 / Supabase / WhatsApp 号码。Compose 与安装步骤按上游官方套件编写，请你在 VPS 实测 |
| **本地 `pnpm dev`（贡献者路径）** | ⚠️ **未跑通** — 验证机 Node **20.19.2**，上游 `.nvmrc` 要求 **22**；且需自备 Supabase +（可选）WAHA |
| **真实 AI 对话 / WhatsApp QR 收发** | ⚠️ **未验证** — 需自备 OpenRouter/Anthropic/OpenAI Key 与可扫码号码 |

可复现探针：

```bash
./scripts/probe-ghcr.sh
./scripts/preflight.sh
```

---

## 选哪条路？

| 场景 | 推荐 |
|------|------|
| **要用 CRM 做生意 / 接 WhatsApp** | **路径 A：VPS + `hostgator-setup-kit/install.sh`**（官方主路径，预构建镜像，不在 VPS 上编译） |
| VPS 想顺带自托管 Supabase | 路径 A′：套件内 single-server / 相关 override（见上游 kit README） |
| 改代码、提 PR | **路径 B：开发机** Node 22 + pnpm + `baseline.sql` + 可选 `docker compose up`（WAHA）——**不是**给最终用户的安装方式 |
| 只想确认镜像能不能下 | `./scripts/probe-ghcr.sh` 或（有 Docker 时）`docker compose -f docker-compose.images-ref.yml --profile ref-only pull` |

下面以 **路径 A** 为主写可跟做步骤。

---

## 环境要求（路径 A）

| 项 | 建议 |
|----|------|
| VPS | **x86_64 或 ARM64**，**约 4 GB RAM**（2 GB 可能勉强启动，WAHA 多会话会紧） |
| 系统 | 常见 Ubuntu 等；需能装 Docker（`install.sh` 可代装） |
| 域名 | 一条 **A 记录** 指到 VPS；用于 Caddy/Let’s Encrypt 或你已有的 Traefik |
| 数据库 | [Supabase](https://supabase.com) 免费项目：**URL + anon + service_role + Session pooler 连接串** |
| AI | OpenRouter / Anthropic / OpenAI 之一（可装完再在界面填） |
| WhatsApp | 可扫 QR 的号码（或后续 Meta 官方通道） |
| 端口 | **80 / 443**（若已被面板代理占用，走 Traefik 覆盖，不要硬抢） |

可选先体检：

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-deskcommcrm.git
cd cn-deploy-deskcommcrm
./scripts/preflight.sh
# 若已装 cn-deploy-doctor，也可再跑一遍网络/磁盘体检
```

---

## 路径 A｜VPS 一键安装（官方主路径）

### 1. SSH 进 VPS

```bash
ssh -p PORT root@YOUR_IP
# 密码输入时屏幕无回显是正常现象
```

### 2. 克隆上游**发布标签**（推荐）

```bash
# 本仓包装：
git clone https://github.com/fisheeplife-beep/cn-deploy-deskcommcrm.git
cd cn-deploy-deskcommcrm
DESKCOMM_TAG=v1.97.0 ./scripts/clone-upstream.sh
cd data/upstream-DeskcommCRM
```

或手写：

```bash
git clone --depth 1 --branch v1.97.0 https://github.com/melgarafael/DeskcommCRM.git
cd DeskcommCRM
```

> 国内 clone 慢：见 [`docs/china-network.md`](./docs/china-network.md)。

### 3. （推荐）钉死镜像版本

把本仓片段合并进即将使用的 `.env`，避免 `latest` 漂到 main：

```bash
# 在配套仓根目录
cat deploy-snippets/images.env
# 安装器也会写入版本；手工 --yes 时请三张镜像同一版本号
```

### 4. 准备 Supabase

1. 控制台新建项目，复制 **Project URL**、**anon**、**service_role**。  
2. Database 设置里复制 **Session pooler** 连接串（**不要**用 Direct、IPv6-only 那条——国内/多数 VPS 会连不上）。  
3. 或在安装前：

```bash
export SUPABASE_ACCESS_TOKEN=sbp_你的令牌   # supabase.com/dashboard/account/tokens
# install.sh 可代建项目并探测 pooler（令牌权限极大，勿提交进 git）
```

### 5. 跑安装器

```bash
bash hostgator-setup-kit/install.sh
```

它会问：域名、Supabase、AI 提供商、管理员邮箱密码等；**技术密钥会自动生成**。  
缺 Docker 时会询问并用官方 `get.docker.com` 安装。

非交互：

```bash
# 先把本仓 .env.example 改成真实 .env，再：
cp /path/to/cn-deploy-deskcommcrm/.env .env
bash hostgator-setup-kit/install.sh --yes
```

本仓快捷准备（**仍建议在 VPS 上**把 `DESKCOMM_RUN_INSTALL=1`）：

```bash
cp .env.example .env   # 编辑
./scripts/start-vps-install.sh
# 确认后：
DESKCOMM_RUN_INSTALL=1 DESKCOMM_NONINTERACTIVE=1 ./scripts/start-vps-install.sh
```

### 6. 安装器实际做了什么（便于对照日志）

1. 生成内部密钥与 WAHA 相关密钥  
2. 在 Postgres 上应用 **`supabase/baseline.sql`**（完整 schema；**不是**空的 stub migrations）  
3. 创建首个管理员  
4. `docker-compose.prod.yml` 拉起 **Caddy + app + WAHA + Redis/SRH + worker + scheduler** 等，并做健康检查  
5. 安装自动化 cron（否则 WHEN/IF/THEN 规则只排队不执行）与「屏幕更新」代理  

脚本**可重复执行**（幂等），不会故意重复建用户/cron。

### 7. 首次登录与 WhatsApp

1. 浏览器打开 `https://你的域名`（证书约 1 分钟）  
2. 用安装时的管理员账号登录；MFA **可选**（设置里再开）  
3. Onboarding 扫 QR 绑定 WhatsApp  
4. 健康检查：

```bash
bash hostgator-setup-kit/healthcheck.sh
# 或从外网（若路由暴露了 health；许多部署仅内网可探）
BASE_URL=https://你的域名 ./scripts/verify-health.sh
```

期望：JSON 中出现 `"status":"ok"`（子系统降级时脚本会警告）。

### 8. 更新

- **界面**：侧栏「新版本」→ 设置 → 更新（自动备份库；宿主 cron 最多约 5 分钟接手）  
- **终端**：`bash hostgator-setup-kit/update.sh`（目标是**已发布 release**，不是裸 `main`）

---

## 已有反向代理的 VPS（Coolify / Dokploy / Hostinger…）

若 80/443 已被面板 Traefik 占用：

- 安装器多数情况会检测并写 `REVERSE_PROXY=traefik`  
- 手动时：`docker compose -f docker-compose.prod.yml -f docker-compose.traefik.yml up -d`  
- Hostinger 一类 `--network host` 代理：安装器可能**停下来问你**；`--yes` 前请在 `.env` 显式声明  

细节以上游 `hostgator-setup-kit/README.md` 为准。

---

## 路径 B｜本地开发（仅贡献代码）

> 官方原文强调：**要用 CRM，走 VPS 安装器**，不要把开发步骤当成产品安装。

```bash
git clone https://github.com/melgarafael/DeskcommCRM.git
cd DeskcommCRM
nvm use          # Node 22
npm i -g pnpm@9 && pnpm install
cp .env.example .env.local   # 按 docs/SETUP.md 填全（葡语长文）

docker compose up -d         # 可选：本地 WAHA 等
# Schema：对数据库执行 supabase/baseline.sql（勿指望 db push 从零建满）
pnpm dev
# http://localhost:3000  ·  http://localhost:3000/api/v1/health
```

本仓验证机 Node 20，**未**执行该路径。

---

## 国内网络要点（摘要）

- **GHCR**：三张预构建镜像必须可拉；失败时配 Docker 代理或镜像中转，**不要**在小内存 VPS 上强制源码 build app  
- **Docker Hub**：WAHA；注意限流与架构  
- **Supabase pooler**：避开 IPv6 Direct  
- **AI API**：大陆机房直连 OpenAI/Anthropic 常需代理或 OpenRouter  

全文：[`docs/china-network.md`](./docs/china-network.md) · 排错：[`docs/troubleshooting.md`](./docs/troubleshooting.md)

---

## 本仓文件地图

```
cn-deploy-deskcommcrm/
├── README.zh-CN.md          # 本长文（跟做入口）
├── README.md                # 英文短述 + 指向中文
├── .env.example             # 最小必填集（完整字段看上游 hostgator example）
├── docker-compose.images-ref.yml  # 仅镜像坐标参考（非完整生产栈）
├── deploy-snippets/images.env
├── scripts/
│   ├── preflight.sh         # 主机预检
│   ├── probe-ghcr.sh        # 无 Docker 探测 GHCR
│   ├── clone-upstream.sh    # 浅克隆指定 tag
│   ├── start-vps-install.sh # 准备树与 .env，可选调用 install.sh
│   └── verify-health.sh     # 探 /api/v1/health
├── docs/
│   ├── china-network.md
│   └── troubleshooting.md
└── examples/ghcr-probe.txt  # 作者环境探针留档
```

---

## 声明

- DeskcommCRM 版权与商标归上游作者；本仓 MIT 仅覆盖**配套脚本与中文说明**  
- 自托管即你对服务器、客户数据、WhatsApp 账号与合规（含 LGPD/个保法语境）自行负责  
- 费率、镜像 tag、安装器行为以上游当日文档与 release 为准；发现漂移请开 Issue  

上游支持：GitHub Issues / Discussions；安全问题走上游 Security Advisory，勿公开贴密钥。
