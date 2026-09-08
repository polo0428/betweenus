import Foundation

enum AppConfiguration {
    /// 部署中转服务（见 server/ 目录）后替换为你的 Worker 域名
    static let apiBaseURL = URL(string: "https://betweenus-relay.polohuang0428.workers.dev")!
}

/// Composition Root：唯一负责创建和连接所有模块的地方
@MainActor
struct AppContainer {
    let api: APIClient
    let credentials: CredentialStore
    let local: ConnectionSession
    let remote: RemoteTransport
    let router: TouchRouter
    let pairing: PairingModel
    let push: PushReceiver
    let poller: PendingTouchPoller
    let customStore: CustomTouchStore

    static func make() -> AppContainer {
        let credentials = CredentialStore()
        let api = APIClient(baseURL: AppConfiguration.apiBaseURL, session: .shared)
        let local = ConnectionSession()
        let remote = RemoteTransport(api: api, credentials: credentials)
        let router = TouchRouter(local: local, remote: remote)
        let push = PushReceiver(local: local, remote: remote, api: api, credentials: credentials)
        let pairing = PairingModel(api: api, credentials: credentials)
        let customStore = CustomTouchStore()
        let poller = PendingTouchPoller(api: api, credentials: credentials) { [push] payload in
            push.receive(payload: payload)
        } onAck: { [router] in
            router.receiveAck()
        }

        pairing.onBound = { [push] in
            push.reportTokenIfNeeded()
        }

        // 自定义触感列表变化 → 全量同步到 Watch（Watch 无键盘，选项列表由 iPhone 维护）
        customStore.onChange = { [local] titles in
            local.syncCustomTouches(titles)
        }

        // Watch 主动发送：iPhone 收到 Watch 的消息后走远程通道发给伴侣
        local.onReceiveFromWatch = { [remote] payload in
            Task { await remote.send(payload: payload) }
        }

        return AppContainer(
            api: api,
            credentials: credentials,
            local: local,
            remote: remote,
            router: router,
            pairing: pairing,
            push: push,
            poller: poller,
            customStore: customStore
        )
    }
}