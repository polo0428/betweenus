import SwiftUI

struct ConnectionStatusCard: View {
    let isPaired: Bool
    let lastStatus: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isPaired ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                Circle()
                    .strokeBorder((isPaired ? Color.green : Color.orange).opacity(0.28), lineWidth: 10)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isPaired ? "Apple Watch 已连接" : "等待 Apple Watch 连接")
                    .font(.headline)
                Text(lastStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "wave.3.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
