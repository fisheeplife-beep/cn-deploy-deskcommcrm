# deploy-snippets

这里**不**复制上游完整 `docker-compose.prod.yml`（含 Caddy / WAHA / Redis / scheduler，且随版本频繁改）。

正确做法：

1. `git clone` / `checkout` 上游发布标签（如 `v1.97.0`）
2. 用本仓 `.env.example` 或 `images.env` 填 `.env`
3. 跑上游 `bash hostgator-setup-kit/install.sh`

`images.env` 只是「把三张 GHCR 镜像钉到同一版本」的片段，可 `source` 或合并进 `.env`。
