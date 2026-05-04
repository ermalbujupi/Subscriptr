import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.cancelledDate == nil },
        sort: \Subscription.name
    ) private var activeSubscriptions: [Subscription]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    subscriptionList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }

    private var totalMonthlySpend: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            Text("Monthly Spend")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text(totalMonthlySpend, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("\(activeSubscriptions.count) active subscription\(activeSubscriptions.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var subscriptionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Subscriptions")
                .font(.headline)

            if activeSubscriptions.isEmpty {
                ContentUnavailableView(
                    "No Subscriptions",
                    systemImage: "plus.circle",
                    description: Text("Add your first subscription to get started")
                )
                .frame(minHeight: 200)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(activeSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                        if subscription.id != activeSubscriptions.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: subscription.category.color))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body.weight(.medium))

                if let nextDate = subscription.nextRenewalDate {
                    Text("Renews \(nextDate, format: .dateTime.month().day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(subscription.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.body.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Subscription.self, Card.self], inMemory: true)
}
