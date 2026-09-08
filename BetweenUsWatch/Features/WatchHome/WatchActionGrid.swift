import SwiftUI

struct WatchActionGrid: View {
    let onSend: (TouchKind) -> Void

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            watchButton(title: "想你了", symbol: "heart.fill", tint: .pink) {
                onSend(.missYou)
            }
            watchButton(title: "抱一下", symbol: "hands.clap.fill", tint: .orange) {
                onSend(.hug)
            }
            watchButton(title: "在想你", symbol: "bubble.left.and.bubble.right.fill", tint: .purple) {
                onSend(.thinking)
            }
            watchButton(title: "晚安", symbol: "moon.fill", tint: .indigo) {
                onSend(.goodNight)
            }
        }
    }

    private func watchButton(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                Spacer(minLength: 4)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .padding(10)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.28), tint.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
