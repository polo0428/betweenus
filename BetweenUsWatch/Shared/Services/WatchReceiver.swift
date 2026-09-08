import Foundation
import WatchConnectivity
import WatchKit

class WatchReceiver: NSObject, ObservableObject, WCSessionDelegate {
    @Published var status = "已准备"

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ touch: TouchKind) {
        guard WCSession.default.isReachable else {
            status = "iPhone 暂不可达"
            return
        }

        WCSession.default.sendMessage(["touch": touch.rawValue], replyHandler: nil, errorHandler: nil)
        WKInterfaceDevice.current().play(.click)
        status = "已发送 \(touch.title)"
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let raw = message["touch"] as? String, let touch = TouchKind(rawValue: raw) else { return }
        DispatchQueue.main.async {
            WKInterfaceDevice.current().play(touch.haptic)
            self.status = "收到：\(touch.title)"
        }
    }
}
