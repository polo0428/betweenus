import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// MARK: - 分类

enum TouchCategory: String, CaseIterable, Identifiable {
    case daily, love, special

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "日常"
        case .love: "心意"
        case .special: "特别"
        }
    }

    /// 该分类下的预设触感（按枚举声明顺序）
    var kinds: [TouchKind] {
        TouchKind.allCases.filter { $0.category == self }
    }
}

// MARK: - 预设触感

enum TouchKind: String, CaseIterable, Identifiable {
    // 日常
    case goodMorning, busy, home, cheerUp
    // 心意
    case missYou, hug, loveYou, sorry
    // 特别
    case thinking, goodNight

    var id: String { rawValue }

    var category: TouchCategory {
        switch self {
        case .goodMorning, .busy, .home, .cheerUp: .daily
        case .missYou, .hug, .loveYou, .sorry: .love
        case .thinking, .goodNight: .special
        }
    }

    var title: String {
        switch self {
        case .goodMorning: "早安"
        case .busy: "在忙"
        case .home: "到家了"
        case .cheerUp: "加油"
        case .missYou: "想你了"
        case .hug: "抱一下"
        case .loveYou: "爱你"
        case .sorry: "对不起"
        case .thinking: "在想你"
        case .goodNight: "晚安"
        }
    }

    var subtitle: String {
        switch self {
        case .goodMorning: "把清晨的第一个问候送过去"
        case .busy: "告诉对方你在忙，晚点回复"
        case .home: "平安到家的信号"
        case .cheerUp: "给对方一点力量"
        case .missYou: "把想念轻轻送过去"
        case .hug: "给对方一个拥抱"
        case .loveYou: "最直接的那三个字"
        case .sorry: "先迈出台阶的那一步"
        case .thinking: "让对方知道你在想"
        case .goodNight: "把今晚收好"
        }
    }

    var symbol: String {
        switch self {
        case .goodMorning: "sun.max.fill"
        case .busy: "clock.fill"
        case .home: "house.fill"
        case .cheerUp: "bolt.fill"
        case .missYou: "heart.fill"
        case .hug: "hands.clap.fill"
        case .loveYou: "heart.circle.fill"
        case .sorry: "hand.raised.fill"
        case .thinking: "bubble.left.and.bubble.right.fill"
        case .goodNight: "moon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .goodMorning: .yellow
        case .busy: .gray
        case .home: .green
        case .cheerUp: .orange
        case .missYou: .pink
        case .hug: .orange
        case .loveYou: .red
        case .sorry: .blue
        case .thinking: .purple
        case .goodNight: .indigo
        }
    }

    #if os(watchOS)
    var haptic: WKHapticType {
        self == .goodNight ? .notification : .click
    }
    #endif
}