# BetweenUs 中转服务部署

`worker.js` 是 Cloudflare Workers 实现：配对关系存 KV，触感通过 APNs 转发给伴侣手机。

## 1. Apple 开发者配置（APNs）

1. [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list) 新建 **Apple Push Notifications service (APNs)** 密钥，下载 `.p8` 文件，记下 **Key ID** 和 **Team ID**
2. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) 确认 `com.betweenus.app` 的 App ID 已勾选 **Push Notifications** 能力
3. Xcode 打开工程 → target `BetweenUs` → **Signing & Capabilities** → 确认已包含 Push Notifications（entitlements 文件已随代码提供）

## 2. 部署 Worker

```bash
# 安装 Wrangler 并登录
npm install -g wrangler
wrangler login

# 创建 KV 命名空间
wrangler kv:namespace create BETWEENUS_KV
# 把返回的 namespace id 填进 wrangler.toml（见下）

# 设置密钥
wrangler secret put APNS_KEY_ID        # 例：AB12CD34EF
wrangler secret put APNS_TEAM_ID       # 例：X1Y2Z3A4B5
wrangler secret put APNS_AUTH_KEY      # 粘贴 .p8 文件完整内容（含 BEGIN/END 行）
wrangler secret put APNS_BUNDLE_ID     # com.betweenus.app
wrangler secret put APNS_PRODUCTION    # 开发阶段填 false（sandbox），上架填 true

# 部署
wrangler deploy worker.js
```

`wrangler.toml` 最小配置：

```toml
name = "betweenus-relay"
main = "worker.js"
compatibility_date = "2024-01-01"

kv_namespaces = [
  { binding = "BETWEENUS_KV", id = "上一步返回的 namespace id" }
]
```

## 3. 客户端指向你的 Worker

部署成功后 Worker 获得一个域名（如 `https://betweenus-relay.<your-subdomain>.workers.dev`），把它填进：

```
BetweenUs/Shared/AppContainer.swift → AppConfiguration.apiBaseURL
```

重新构建即可。

## 4. 验证

1. 两台设备（或模拟器）各自打开 App，点右上角配对按钮
2. A 生成配对码 → B 输入 → 双方都显示"已配对"
3. A 关掉蓝牙/远离（或退出 Watch 配对状态）后点"想你了"
4. B 应收到横幅："对方发来一个触感：想你了"，且若 B 的 Watch 已连接会同步震动