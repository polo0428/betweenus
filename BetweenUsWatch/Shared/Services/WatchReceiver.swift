import Foundation
import WatchConnectivity
import WatchKit

class WatchReceiver: NSObject, ObservableObject, WCSessionDelegate {
    @Published var status = "已准备"
    /// iPhone 同步来的自定义触感列表（applicationContext 全量快照）
    @Published var customTouches: [String] = []

    /// 发送面板全部选项：8 个预设 + 自定义（按创建顺序排在后面）
    var allItems: [TouchItem] {
        TouchKind.allCases.map { TouchItem.preset($0) } + customTouches.map { TouchItem.custom($0) }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ item: TouchItem) {
        send(payload: item.payload, status: "已发送 \(item.title)")
    }

    func sendRhythm(_ rhythm: Rhythm) {
        send(payload: rhythm.payload, status: "已发送节奏（\(rhythm.tapCount) 击）")
    }

    private func send(payload: String, status: String) {
        guard WCSession.default.isReachable else {
            self.status = "iPhone 暂不可达"
            return
        }

        WCSession.default.sendMessage(["touch": payload], replyHandler: nil, errorHandler: nil)
        WKInterfaceDevice.current().play(.click)
        self.status = status
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    /// iPhone 端自定义触感列表变化时同步过来
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let titles = applicationContext["customTouches"] as? [String] else { return }
        DispatchQueue.main.async {
            self.customTouches = titles
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let raw = message["touch"] as? String,
              let touch = IncomingTouch(kind: raw) else { return }
        DispatchQueue.main.async {
            if let rhythm = touch.rhythm {
                RhythmEngine.shared.play(rhythm)
            } else if let kind = TouchKind(rawValue: raw) {
                WKInterfaceDevice.current().play(kind.haptic)
            } else {
                WKInterfaceDevice.current().play(.click)
            }
            self.status = "收到：\(touch.title)"
        }
    }
}