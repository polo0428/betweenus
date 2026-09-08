import SwiftUI

/// 接收到的触感消息：预设自动映射图标/颜色，自定义直接展示原文，rhythm: 前缀为敲击节奏。
/// 两端（iPhone / Watch）共用的解析层，保证不认识预设 kind 时按自定义文案展示。
struct IncomingTouch: Identifiable {
    let kind: String
    let title: String
    let symbol: String
    let tint: Color
    let isCustom: Bool
    /// 非空表示这是一段可回放的敲击节奏（仅 Watch 端消费）
    let rhythm: Rhythm?

    var id: String { kind }

    init?(kind: String) {
        guard !kind.isEmpty, kind != "ack" else { return nil }
        self.kind = kind

        if kind.hasPrefix(Rhythm.payloadPrefix) {
            rhythm = Rhythm(payload: kind)
            title = "敲击节奏"
            symbol = "metronome"
            tint = .orange
            isCustom = true
        } else if let preset = TouchKind(rawValue: kind) {
            rhythm = nil
            title = preset.title
            symbol = preset.symbol
            tint = preset.tint
            isCustom = false
        } else {
            rhythm = nil
            title = kind
            symbol = "sparkles"
            tint = .teal
            isCustom = true
        }
    }
}