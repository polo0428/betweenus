import SwiftUI

struct ContentView: View {
    @StateObject private var router: TouchRouter
    @StateObject private var pairing: PairingModel
    @StateObject private var push: PushReceiver
    @State private var showPairing = false

    @MainActor
    init(container: AppContainer) {
        _router = StateObject(wrappedValue: container.router)
        _pairing = StateObject(wrappedValue: container.pairing)
        _push = StateObject(wrappedValue: container.push)
    }

    var body: some View {
        BetweenUsHomeView(
            isPaired: router.isLocalWatchPaired,
            lastStatus: router.statusMessage,
            onSend: { router.send($0) }
        )
        .task {
            router.activateLocal()
            push.registerForRemoteNotifications()
        }
        .overlay(alignment: .topTrailing) {
            pairingButton
        }
        .overlay(alignment: .top) {
            if let received = push.lastReceived {
                incomingBanner(received)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var pairingButton: some View {
        Button {
            showPairing = true
        } label: {
            Image(systemName: pairing.isPaired ? "person.2.fill" : "person.2.badge.plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.pink)
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())
        }
        .padding(.top, 6)
        .padding(.trailing, 16)
        .sheet(isPresented: $showPairing) {
            PairingView(model: pairing)
        }
    }

    private func incomingBanner(_ touch: TouchKind) -> some View {
        HStack(spacing: 10) {
            Image(systemName: touch.symbol)
                .foregroundStyle(touch.tint)
            Text("对方发来：\(touch.title)")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 54)
        .task(id: touch.id) {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if push.lastReceived?.id == touch.id {
                push.lastReceived = nil
            }
        }
    }
}