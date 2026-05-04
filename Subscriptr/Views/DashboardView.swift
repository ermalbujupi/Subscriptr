import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(
        filter: #Predicate<Subscription> { $0.cancelledDate == nil },
        sort: \Subscription.name
    ) private var activeSubscriptions: [Subscription]

    private var totalMonthlySpend: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    private var upcomingRenewals: [Subscription] {
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        return activeSubscriptions
            .filter { sub in
                guard let next = sub.nextRenewalDate else { return false }
                return next <= horizon
            }
            .sorted { ($0.nextRenewalDate ?? .distantFuture) < ($1.nextRenewalDate ?? .distantFuture) }
    }

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    if !upcomingRenewals.isEmpty {
                        upcomingSection
                    }
                    allSubscriptionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingAddSheet) {
                SubscriptionFormView()
            }
        }
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
                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Renewing Soon", systemImage: "bell.badge")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(spacing: 0) {
                ForEach(upcomingRenewals) { subscription in
                    NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                        UpcomingRenewalRow(subscription: subscription)
                    }
                    .buttonStyle(.plain)
                    if subscription.id != upcomingRenewals.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var allSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Subscriptions")
                .font(.headline)

            if activeSubscriptions.isEmpty {
                ContentUnavailableView(
                    "No Subscriptions",
                    systemImage: "plus.circle",
                    description: Text("Tap to add your first subscription")
                )
                .frame(minHeight: 200)
                .contentShape(Rectangle())
                .onTapGesture { showingAddSheet = true }
            } else {
                VStack(spacing: 0) {
                    ForEach(activeSubscriptions) { subscription in
                        NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                            SubscriptionRowView(subscription: subscription)
                        }
                        .buttonStyle(.plain)
                        if subscription.id != activeSubscriptions.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct UpcomingRenewalRow: View {
    let subscription: Subscription

    private var daysUntilRenewal: Int? {
        guard let next = subscription.nextRenewalDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: next).day
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hexString: subscription.category.color))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body.weight(.medium))

                if let days = daysUntilRenewal {
                    Text(days == 0 ? "Renews today" : days == 1 ? "Renews tomorrow" : "Renews in \(days) days")
                        .font(.caption)
                        .foregroundStyle(.orange)
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

struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hexString: subscription.category.color))
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

#Preview {
    DashboardView()
        .modelContainer(for: [Subscription.self, Card.self], inMemory: true)
}
