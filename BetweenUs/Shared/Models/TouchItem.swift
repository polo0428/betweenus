import SwiftUI

/// 触感项：预设枚举 或 用户自定义文案，统一发送/展示单位
enum TouchItem: Identifiable, Hashable {
    case preset(TouchKind)
    case custom(String)

    var id: String {
        switch self {
        case .preset(let kind): return kind.rawValue
        case .custom(let text): return "custom:\(text)"
        }
    }

    /// 线上传输的 payload（WCSession / Worker 的 kind 字段）
    var payload: String {
        switch self {
        case .preset(let kind): return kind.rawValue
        case .custom(let text): return text
        }
    }

    var title: String {
        switch self {
        case .preset(let kind): return kind.title
        case .custom(let text): return text
        }
    }

    var subtitle: String {
        switch self {
        case .preset(let kind): return kind.subtitle
        case .custom: return "自定义"
        }
    }

    var symbol: String {
        switch self {
        case .preset(let kind): return kind.symbol
        case .custom: return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .preset(let kind): return kind.tint
        case .custom: return .teal
        }
    }
}