import SwiftUI

struct BetweenUsHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.pink, in: Circle())

                Text("腕间触感")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text("BetweenUs")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)

            Text("轻轻一触，把想念送到对方手腕上。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
