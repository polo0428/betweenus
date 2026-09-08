import Foundation
import UserNotifications
import UIKit

@MainActor
final class PushReceiver: NSObject, ObservableObject {
    @Published var lastReceived: TouchKind?
    @Published var deviceToken: String?
    @Published var registrationError: String?

    private let local: ConnectionSession
    private let api: APIClient
    private let credentials: CredentialStore

    init(local: ConnectionSession, api: APIClient, credentials: CredentialStore) {
        self.local = local
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

    /// 所有接收通道（APNs / 轮询）的统一入口
    func receive(_ touch: TouchKind) {
        lastReceived = touch
        local.send(touch)
    }

    /// 收到推送：更新横幅 + 转发本地 Watch 震动
    private func handleIncoming(_ userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo["kind"] as? String,
              let touch = TouchKind(rawValue: raw) else { return }
        receive(touch)
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