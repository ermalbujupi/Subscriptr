import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            Text("Subscriptions")
                .tabItem {
                    Label("Subs", systemImage: "list.bullet")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Subscription.self, Card.self], inMemory: true)
}
