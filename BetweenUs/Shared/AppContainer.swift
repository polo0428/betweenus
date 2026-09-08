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

    static func make() -> AppContainer {
        let credentials = CredentialStore()
        let api = APIClient(baseURL: AppConfiguration.apiBaseURL, session: .shared)
        let local = ConnectionSession()
        let remote = RemoteTransport(api: api, credentials: credentials)
        let router = TouchRouter(local: local, remote: remote)
        let push = PushReceiver(local: local, remote: remote, api: api, credentials: credentials)
        let pairing = PairingModel(api: api, credentials: credentials)
        let poller = PendingTouchPoller(api: api, credentials: credentials) { [push] touch in
            push.receive(touch)
        } onAck: { [router] in
            router.receiveAck()
        }

        pairing.onBound = { [push] in
            push.reportTokenIfNeeded()
        }

        // Watch 主动发送：iPhone 收到 Watch 的消息后走远程通道发给伴侣
        local.onReceiveFromWatch = { [remote] touch in
            Task { await remote.send(touch) }
        }

        return AppContainer(
            api: api,
            credentials: credentials,
            local: local,
            remote: remote,
            router: router,
            pairing: pairing,
            push: push,
            poller: poller
        )
    }
}