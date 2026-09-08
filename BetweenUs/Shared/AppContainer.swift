import Foundation

enum AppConfiguration {
    /// 部署中转服务（见 server/ 目录）后替换为你的 Worker 域名
    static let apiBaseURL = URL(string: "https://api.betweenus.app")!
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

    static func make() -> AppContainer {
        let credentials = CredentialStore()
        let api = APIClient(baseURL: AppConfiguration.apiBaseURL, session: .shared)
        let local = ConnectionSession()
        let remote = RemoteTransport(api: api, credentials: credentials)
        let router = TouchRouter(local: local, remote: remote)
        let push = PushReceiver(local: local, api: api, credentials: credentials)
        let pairing = PairingModel(api: api, credentials: credentials)

        pairing.onBound = { [push] in
            push.reportTokenIfNeeded()
        }

        return AppContainer(
            api: api,
            credentials: credentials,
            local: local,
            remote: remote,
            router: router,
            pairing: pairing,
            push: push
        )
    }
}