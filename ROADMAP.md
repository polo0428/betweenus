# BetweenUs Roadmap

> 定位：Watch 优先的亲密关系触感通信。一句话、一个震动，把"我在想你"变成腕上的物理信号。
> 更新：2026-03（基于 v0.0.1 功能盘点 + LoveTouch / Love Pulse 竞品对比）

## 现状（v0.0.1 已上线）

- 8 个预设触感（心意/特别/日常三类）+ 自定义文字触感（≤10 字，payload 自包含）
- 双通道传输：WCSession 本地直连（iPhone↔Watch）/ Cloudflare Worker 中转（异地，15 秒前台轮询）
- 6 位配对码绑定，Token 存 Keychain；已读回执（自动 ack）
- 消息取走即删（KV 暂存 ≤24h），隐私叙事强

## 竞品对比结论

| 维度 | BetweenUs | LoveTouch（仅 Watch） | Love Pulse（iPhone 为主） |
|------|-----------|----------------------|--------------------------|
| 触感类型 | 单一震动 + 语义文案 | 可录制敲击节奏（Secret Touch Language） | 心跳 nudge + 同步动画 |
| 生理信号 | 无 | 实时心率共享（HealthKit） | 无 |
| 情感留存 | 已读回执 | 共享倒计时（纪念日/重逢） | 协作记忆板 |
| 后台可达 | ✗ 前台轮询（硬伤） | ✓ APNs | ✓ 推送 |
| 端覆盖 | iPhone + Watch 全链路 | 仅 Watch | 仅 iPhone |

核心判断：**可用性硬伤（后台不可达）> 差异化触感（敲击节奏）> 情感留存 > 生理信号**。

## 路线

### v0.2 —— 可用性补齐（依赖付费开发者账号 $99/年）
1. **APNs 后台推送**：Worker 端代码已就绪（`sendApns`/`apnsJWT`），只差 APNs Auth Key + `device/register` 打通；免费账号无 push capability，因此前置条件是付费账号
2. 锁屏补达体验优化（打开 App 时的未读触感聚合展示）

### v0.3 —— 差异化：自定义敲击节奏（本次技术验证启动）
- 数据模型：间隔序列 `gaps: [ms]`，payload `rhythm:120,300,120`
- Watch 端录制（点按采样）+ 回放引擎（方案 A：时序 `WKHapticType.click`；方案 B：`play(_:Data:)` haptic 文件）
- 详见 `docs/rhythm-spike.md`（验证产出）

### v0.4 —— 情感留存
- 共享倒计时（纪念日/下次见面），Worker 加一个 `countdown` 端点即可，复用配对体系
- 触感历史（本地存储 + 简单时间线视图）

### v0.5+ —— 暂缓（做了很酷但偏离核心）
- 心跳共享（HealthKit + 双端在线，成本高，LoveTouch 已占位）
- 协作记忆板、照片分享（向通用 IM 漂移，不做）
- 主题内购变现（等 DAU 有量再说）

## 技术债
- worker `isCustomKind` 按字符长度校验，emoji 计数两端不一致（Swift grapheme vs JS UTF-16），罕见场景误拒
- 免费账号签名 7 天过期，TestFlight/分发依赖付费账号