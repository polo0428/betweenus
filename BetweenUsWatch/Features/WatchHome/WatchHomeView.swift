import SwiftUI

struct WatchHomeView: View {
    @StateObject private var receiver: WatchReceiver

    init(receiver: WatchReceiver = WatchReceiver()) {
        _receiver = StateObject(wrappedValue: receiver)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                WatchActionGrid(items: receiver.allItems) { item in
                    receiver.send(item)
                }
                statusCard
            }
            .padding(12)
        }
        .background(pageBackground.ignoresSafeArea())
        .task { receiver.activate() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.pink, in: Circle())

            Text("BetweenUs")
                .font(.headline.weight(.semibold))

            Text("把一句话，变成腕间的触感。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statusCard: some View {
        Text(receiver.status)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var pageBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.11),
                Color(red: 0.13, green: 0.13, blue: 0.17)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Preview lives in WatchHomePreviewView.swift so Canvas can use a lighter mock view.
