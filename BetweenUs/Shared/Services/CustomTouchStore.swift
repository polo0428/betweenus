import Foundation

/// 自定义触感列表：iPhone 端编辑，经 WCSession applicationContext 同步到 Watch
@MainActor
final class CustomTouchStore: ObservableObject {
    @Published var touches: [String] {
        didSet {
            UserDefaults.standard.set(touches, forKey: defaultsKey)
            onChange?(touches)
        }
    }

    /// 列表变化时同步到 Watch（由装配方注入）
    var onChange: (([String]) -> Void)?

    private let defaultsKey = "customTouches"

    init() {
        touches = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed != "ack",
              !touches.contains(trimmed) else { return }
        touches.append(trimmed)
    }

    func remove(_ title: String) {
        touches.removeAll { $0 == title }
    }
}