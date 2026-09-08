# BetweenUs 中转服务部署

`worker.js` 是 Cloudflare Workers 实现：配对关系存 KV，触感通过**双通道**转发：

1. **轮询通道**（始终启用，零账号成本）：触感暂存 KV，对方 App 每 15 秒拉取。限制：仅对方 App 在前台时 15 秒内送达。
2. **APNs 通道**（配置密钥后启用）：即时推送，锁屏可达。需要 Apple 付费开发者账号（99 美元/年）。

## 快速开始（仅轮询通道，免费）

1. 注册 [Cloudflare 免费账号](https://dash.cloudflare.com/sign-up)
2. `npm install -g wrangler && wrangler login`
3. 创建 KV 并部署：

```bash
cd server
wrangler kv:namespace create BETWEENUS_KV   # 把返回的 id 填进 wrangler.toml
# wrangler.toml 见下方模板
wrangler deploy worker.js
```

4. 把 Worker 域名填入 `BetweenUs/Shared/AppContainer.swift` 的 `AppConfiguration.apiBaseURL`

## 启用 APNs 通道（可选，即时推送）

1. [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list) 新建 **Apple Push Notifications service (APNs)** 密钥，下载 `.p8` 文件，记下 **Key ID** 和 **Team ID**（需付费开发者账号）
2. Xcode → target `BetweenUs` → **Signing & Capabilities** → 确认 Push Notifications（entitlements 已随代码提供）
3. 设置 secrets：

```bash
wrangler secret put APNS_KEY_ID        # 例：AB12CD34EF
wrangler secret put APNS_TEAM_ID       # 例：X1Y2Z3A4B5
wrangler secret put APNS_AUTH_KEY      # 粘贴 .p8 文件完整内容（含 BEGIN/END 行）
wrangler secret put APNS_BUNDLE_ID     # com.betweenus.app
wrangler secret put APNS_PRODUCTION    # 开发阶段填 false（sandbox），上架填 true
wrangler deploy worker.js
```

## wrangler.toml 模板

```toml
name = "betweenus-relay"
main = "worker.js"
compatibility_date = "2024-01-01"

kv_namespaces = [
  { binding = "BETWEENUS_KV", id = "你的 namespace id" }
]
```

## 验证

1. 两台设备（或模拟器）各自打开 App，点右上角配对按钮
2. A 生成配对码 → B 输入 → 双方都显示"已配对"
3. A 点"想你了"（双方 Watch 都不可达时走远程通道）
4. B 的 App 打开状态下 15 秒内收到横幅："对方发来一个触感：想你了"，Watch 已连接则同步震动