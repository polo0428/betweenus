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

    private var lastSentTitle: String?

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

    func send(_ item: TouchItem) {
        lastSentTitle = item.title

        if remote.isReachable {
            // 已配对：始终发给伴侣；本地 Watch 同步震动作为发送确认
            local.send(payload: item.payload)
            Task {
                statusMessage = await remote.sendAndDescribe(item)
            }
        } else if local.isReachableNow {
            // 未配对：退回本地演示，发给自己的 Watch
            local.send(payload: item.payload)
        } else {
            statusMessage = TransportError.notPaired.localizedDescription
        }
    }

    /// 收到对方的已读回执
    func receiveAck() {
        guard let title = lastSentTitle else { return }
        statusMessage = "对方已收到：\(title)"
    }
}