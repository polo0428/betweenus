import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    var container: AppContainer!

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let container = self.container
        Task { @MainActor in
            container?.push.didReceiveDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        let container = self.container
        Task { @MainActor in
            container?.push.registrationFailed(error.localizedDescription)
        }
    }
}

@main
@MainActor
struct BetweenUsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container = AppContainer.make()

    init() {
        appDelegate.container = container
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}