import SwiftUI
#if os(watchOS)
import WatchKit
#endif

enum TouchKind: String, CaseIterable, Identifiable {
    case missYou, hug, thinking, goodNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .missYou: "想你了"
        case .hug: "抱一下"
        case .thinking: "在想你"
        case .goodNight: "晚安"
        }
    }

    var subtitle: String {
        switch self {
        case .missYou: "把想念轻轻送过去"
        case .hug: "给对方一个拥抱"
        case .thinking: "让对方知道你在想"
        case .goodNight: "把今晚收好"
        }
    }

    var symbol: String {
        switch self {
        case .missYou: "heart.fill"
        case .hug: "hands.clap.fill"
        case .thinking: "bubble.left.and.bubble.right.fill"
        case .goodNight: "moon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .missYou: .pink
        case .hug: .orange
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
