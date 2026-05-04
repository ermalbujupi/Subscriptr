import SwiftUI
import SwiftData

@main
struct SubscriptrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Subscription.self, Card.self])
    }
}
