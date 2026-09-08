import SwiftUI

struct BetweenUsHomeView: View {
    let isPaired: Bool
    let lastStatus: String
    let onSend: (TouchKind) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BetweenUsHeroCard()
                    ConnectionStatusCard(isPaired: isPaired, lastStatus: lastStatus)
                    TouchActionGrid(onSend: onSend)
                    statusFooter
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("BetweenUs")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusFooter: some View {
        Text(lastStatus)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var pageBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.07, green: 0.08, blue: 0.10),
                    Color(red: 0.11, green: 0.12, blue: 0.15)
                ]
                : [
                    Color(red: 0.98, green: 0.97, blue: 0.98),
                    Color(red: 0.95, green: 0.95, blue: 0.98)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.pink.opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 32)
                .offset(x: 60, y: -40)
        }
    }

    @Environment(\.colorScheme) private var colorScheme
}

#Preview("iPhone - Connected") {
    BetweenUsHomeView(
        isPaired: true,
        lastStatus: "预览模式 - Apple Watch 已连接",
        onSend: { _ in }
    )
}

#Preview("iPhone - Waiting") {
    BetweenUsHomeView(
        isPaired: false,
        lastStatus: "预览模式 - 等待连接 Apple Watch",
        onSend: { _ in }
    )
}
