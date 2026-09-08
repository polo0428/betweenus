import Foundation
import UserNotifications
import UIKit

@MainActor
final class PushReceiver: NSObject, ObservableObject {
    @Published var lastReceived: IncomingTouch?
    @Published var deviceToken: String?
    @Published var registrationError: String?

    private let local: ConnectionSession
    private let remote: RemoteTransport
    private let api: APIClient
    private let credentials: CredentialStore

    init(local: ConnectionSession, remote: RemoteTransport, api: APIClient, credentials: CredentialStore) {
        self.local = local
        self.remote = remote
        self.api = api
        self.credentials = credentials
        super.init()
    }

    /// 在 App 启动时调用：挂代理 + 请求权限 + 注册 APNs
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// AppDelegate 回调：拿到 APNs token 后存储，若已配对则立即上报
    func didReceiveDeviceToken(_ data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        reportTokenIfNeeded()
    }

    func registrationFailed(_ message: String) {
        registrationError = message
    }

    /// 已配对时把 APNs token 上报给服务端（配对绑定后也会触发）
    func reportTokenIfNeeded() {
        guard let token = deviceToken,
              let auth = credentials.read(.authToken) else { return }

        struct Body: Encodable { let apnsToken: String }
        Task {
            try? await api.post(.registerToken, body: Body(apnsToken: token), token: auth)
        }
    }

    /// 所有接收通道（APNs / 轮询）的统一入口；payload 为预设 rawValue 或自定义文案
    func receive(payload: String) {
        guard let touch = IncomingTouch(kind: payload) else { return }
        lastReceived = touch
        local.send(payload: payload)
        // 已读回执：收到即自动回传，对方状态栏将更新
        Task { await remote.sendAck() }
    }

    /// 收到推送：解析 payload → 统一入口
    private func handleIncoming(_ userInfo: [AnyHashable: Any]) {
        guard let payload = userInfo["kind"] as? String else { return }
        receive(payload: payload)
    }
}

extension PushReceiver: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        await handleIncoming(userInfo)
        return [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await handleIncoming(response.notification.request.content.userInfo)
    }
}