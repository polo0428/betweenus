import Foundation
import WatchConnectivity

class ConnectionSession: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isPaired = false
    @Published var lastStatus = "准备发送你的第一条触感"

    /// 本地 Watch 当前是否可达（WCSession 通道即时状态）
    var isReachableNow: Bool { WCSession.default.isReachable }

    /// 收到 Watch 端发来的发送请求（Watch 主动发送 → 转发远程通道）
    var onReceiveFromWatch: ((String) -> Void)?

    let session: WCSession

    override init() {
        self.session = .default
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        isPaired = WCSession.default.isPaired
    }

    func send(_ touch: TouchKind) {
        send(payload: touch.rawValue)
    }

    /// 发送触感（预设或自定义，payload 为线上传输的字符串）
    func send(payload: String) {
        guard WCSession.default.isReachable else {
            lastStatus = "Watch 暂不可达，请确认已佩戴并解锁"
            return
        }

        WCSession.default.sendMessage(["touch": payload], replyHandler: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastStatus = "发送失败，请稍后重试"
            }
        }

        lastStatus = "已发送：\(payload)"
    }

    /// 把 iPhone 端自定义触感列表全量同步到 Watch（applicationContext 为快照语义，后写覆盖先写）
    func syncCustomTouches(_ titles: [String]) {
        guard WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(["customTouches": titles])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let raw = message["touch"] as? String else { return }
        DispatchQueue.main.async {
            self.onReceiveFromWatch?(raw)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
