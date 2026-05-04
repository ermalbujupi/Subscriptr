import SwiftUI
import SwiftData

@main
struct SubscriptrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await NotificationService.shared.requestAuthorization()
                }
        }
        .modelContainer(for: [Subscription.self, Card.self])
    }
}
