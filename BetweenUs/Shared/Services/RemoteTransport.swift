import Foundation

struct RemoteTransport {
    let api: APIClient
    let credentials: CredentialStore

    var statusMessage: String { isReachable ? "已配对，可送达对方" : "未配对伴侣" }
    var isReachable: Bool { credentials.read(.authToken) != nil }

    /// 发送触感（预设或自定义，payload 为线上传输的字符串）
    func send(payload: String) async -> TransportResult {
        guard let token = credentials.read(.authToken) else {
            return .failed(TransportError.notPaired.localizedDescription)
        }

        struct Body: Encodable { let kind: String }

        do {
            _ = try await api.post(.sendTouch, body: Body(kind: payload), token: token)
            return .deliveredViaServer
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failed(message)
        }
    }

    /// 供 TouchRouter 直接取展示文案
    func sendAndDescribe(_ item: TouchItem) async -> String {
        switch await send(payload: item.payload) {
        case .deliveredLocally, .deliveredViaServer:
            return "已送达：\(item.title)"
        case .failed(let message):
            return message
        }
    }

    /// 已读回执：收到对方触感后回传，对方状态栏将显示"对方已收到"
    func sendAck() async {
        guard let token = credentials.read(.authToken) else { return }
        struct Body: Encodable { let kind: String }
        _ = try? await api.post(.sendTouch, body: Body(kind: "ack"), token: token)
    }
}