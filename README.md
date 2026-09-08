# BetweenUs

Apple Watch-first 亲密关系触感通信。

## 通信架构

```
发送方 iPhone ──→ TouchRouter ──→ 本地 Watch 可达 ──→ WCSession ──→ 自己的 Watch 震动
                     │
                     └─→ 不可达 ──→ HTTPS ──→ Worker (配对/中转) ──→ APNs ──→ 对方 iPhone ──→ 对方 Watch
```

- **本地通道**：`ConnectionSession`（WCSession），同账号 iPhone ↔ 自己的 Watch，零延迟省电
- **远程通道**：`RemoteTransport` + `PairingService` + `PushReceiver`，异地伴侣间经服务端中转
- **路由**：`TouchRouter` 自动选择通道，UI 无感知
- **装配**：`AppContainer` 是唯一组合所有依赖的地方

## 目录

- `BetweenUs/`：iPhone App
  - `Shared/Services/`：传输协议、本地/远程通道、配对、APNs 接收
  - `Shared/AppContainer.swift`：依赖装配 + API 地址配置
  - `Features/Home/`：主屏 + 配对页
- `BetweenUsWatch/`：Watch App（接收方，WCSession 接收 iPhone 转发）
- `server/`：Cloudflare Workers 中转（配对 + APNs 推送），部署见 `server/README.md`

## 运行

1. 部署 `server/` 中转服务（见 `server/README.md`），把域名填入 `AppConfiguration.apiBaseURL`
2. Xcode 打开 `BetweenUs.xcodeproj`，选 iPhone 模拟器运行
3. Watch 端选 `BetweenUsWatch` scheme + watchOS 模拟器

## 预览

- iPhone：打开 `BetweenUs/Features/Home/BetweenUsHomeView.swift` → Canvas Resume
- Watch：打开 `BetweenUsWatch/Features/WatchHome/WatchHomePreviewView.swift` → Canvas Resume（设备选 watchOS 模拟器）