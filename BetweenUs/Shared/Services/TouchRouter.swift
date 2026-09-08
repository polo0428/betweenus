import Foundation
import Combine

@MainActor
final class TouchRouter: ObservableObject {
    @Published private(set) var statusMessage: String

    let local: ConnectionSession
    let remote: RemoteTransport

    /// HomeView 的"已连接"状态：本地 Watch 可达
    var isLocalWatchPaired: Bool { local.isReachableNow }
    /// 是否与伴侣完成配对（远程通道可用）
    var hasRemotePartner: Bool { remote.isReachable }

    init(local: ConnectionSession, remote: RemoteTransport) {
        self.local = local
        self.remote = remote
        _statusMessage = Published(initialValue: local.lastStatus)
        local.$lastStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$statusMessage)
    }

    func activateLocal() {
        local.activate()
    }

    func send(_ touch: TouchKind) {
        if local.isReachableNow {
            local.send(touch)
        } else {
            Task {
                statusMessage = await remote.sendAndDescribe(touch)
            }
        }
    }
}