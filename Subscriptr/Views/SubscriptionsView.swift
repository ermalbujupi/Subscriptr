import SwiftUI
import SwiftData

struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    @State private var showingAddSheet = false
    @State private var selectedSubscription: Subscription?
    @State private var showCancelled = false

    private var displayed: [Subscription] {
        showCancelled ? subscriptions : subscriptions.filter(\.isActive)
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayed.isEmpty {
                    ContentUnavailableView(
                        showCancelled ? "No Subscriptions" : "No Active Subscriptions",
                        systemImage: "plus.circle",
                        description: Text(showCancelled ? "Add your first subscription." : "All subscriptions are cancelled, or add a new one.")
                    )
                } else {
                    List {
                        ForEach(displayed) { subscription in
                            SubscriptionListRow(subscription: subscription)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedSubscription = subscription }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if subscription.isActive {
                                        Button(role: .destructive) {
                                            cancel(subscription)
                                        } label: {
                                            Label("Cancel", systemImage: "xmark.circle")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        delete(subscription)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCancelled.toggle()
                    } label: {
                        Label(
                            showCancelled ? "Hide Cancelled" : "Show Cancelled",
                            systemImage: showCancelled ? "eye.slash" : "eye"
                        )
                        .labelStyle(.iconOnly)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                SubscriptionFormView()
            }
            .sheet(item: $selectedSubscription) { sub in
                SubscriptionFormView(subscription: sub)
            }
        }
    }

    private func cancel(_ subscription: Subscription) {
        subscription.cancelledDate = .now
    }

    private func delete(_ subscription: Subscription) {
        modelContext.delete(subscription)
    }
}

struct SubscriptionListRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: subscription.category.color).opacity(subscription.isActive ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(subscription.isActive ? .primary : .secondary)

                HStack(spacing: 4) {
                    Text(subscription.category.rawValue)
                    Text("·")
                    Text(subscription.billingCycle.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !subscription.isActive, let cancelled = subscription.cancelledDate {
                    Text("Cancelled \(cancelled, format: .dateTime.month().day().year())")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(subscription.isActive ? .primary : .secondary)

                if let next = subscription.nextRenewalDate {
                    Text(next, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
