import SwiftUI

struct TouchActionGrid: View {
    let onSend: (TouchKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发送触感")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(TouchKind.allCases) { touch in
                    Button {
                        onSend(touch)
                    } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: touch.symbol)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(touch.tint)

                            Spacer(minLength: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(touch.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(touch.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
                        .padding(16)
                        .background(touchBackground(for: touch), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(touch.tint.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func touchBackground(for touch: TouchKind) -> some ShapeStyle {
        LinearGradient(
            colors: [
                touch.tint.opacity(0.18),
                touch.tint.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
