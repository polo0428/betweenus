import SwiftUI

/// 接收到的触感消息：预设自动映射图标/颜色，自定义直接展示原文。
/// 两端（iPhone / Watch）共用的解析层，保证不认识预设 kind 时按自定义文案展示。
struct IncomingTouch: Identifiable {
    let kind: String
    let title: String
    let symbol: String
    let tint: Color
    let isCustom: Bool

    var id: String { kind }

    init?(kind: String) {
        guard !kind.isEmpty, kind != "ack" else { return nil }
        self.kind = kind

        if let preset = TouchKind(rawValue: kind) {
            title = preset.title
            symbol = preset.symbol
            tint = preset.tint
            isCustom = false
        } else {
            title = kind
            symbol = "sparkles"
            tint = .teal
            isCustom = true
        }
    }
}