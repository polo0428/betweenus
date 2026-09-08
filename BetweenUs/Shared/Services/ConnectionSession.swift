import Foundation
import WatchConnectivity

class ConnectionSession: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isPaired = false
    @Published var lastStatus = "准备发送你的第一条触感"

    /// 本地 Watch 当前是否可达（WCSession 通道即时状态）
    var isReachableNow: Bool { WCSession.default.isReachable }

    /// 收到 Watch 端发来的发送请求（Watch 主动发送 → 转发远程通道）
    var onReceiveFromWatch: ((TouchKind) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        isPaired = WCSession.default.isPaired
    }

    func send(_ touch: TouchKind) {
        guard WCSession.default.isReachable else {
            lastStatus = "Watch 暂不可达，请确认已佩戴并解锁"
            return
        }

        WCSession.default.sendMessage(["touch": touch.rawValue], replyHandler: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastStatus = "发送失败，请稍后重试"
            }
        }

        lastStatus = "已发送：\(touch.title)"
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let raw = message["touch"] as? String,
              let touch = TouchKind(rawValue: raw) else { return }
        DispatchQueue.main.async {
            self.onReceiveFromWatch?(touch)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
