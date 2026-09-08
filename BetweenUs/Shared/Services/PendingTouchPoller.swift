import Foundation

/// 轮询通道：无 APNs 时期的异地触感接收方案。
/// 限制：仅 App 在前台时有效（iOS 后台禁止定时轮询），锁屏期间触感会在下次打开时补达。
@MainActor
final class PendingTouchPoller: ObservableObject {
    private let api: APIClient
    private let credentials: CredentialStore
    private let onTouch: (TouchKind) -> Void
    private let interval: UInt64 = 15_000_000_000  // 15 秒

    private var pollingTask: Task<Void, Never>?

    var isRunning: Bool { pollingTask != nil }

    init(api: APIClient, credentials: CredentialStore, onTouch: @escaping (TouchKind) -> Void) {
        self.api = api
        self.credentials = credentials
        self.onTouch = onTouch
    }

    func start() {
        guard pollingTask == nil, credentials.read(.authToken) != nil else { return }
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.pollOnce()
                try? await Task.sleep(nanoseconds: self.interval)
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func pollOnce() async {
        guard let token = credentials.read(.authToken) else { return }

        struct Response: Decodable { let kind: String? }

        do {
            let data = try await api.get(.pendingTouch, token: token)
            guard let response = try? JSONDecoder().decode(Response.self, from: data),
                  let raw = response.kind,
                  let touch = TouchKind(rawValue: raw) else { return }
            onTouch(touch)
        } catch {
            // 网络错误静默，下个周期重试
        }
    }
}