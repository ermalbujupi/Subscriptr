import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let subscription: Subscription

    @Query(
        filter: #Predicate<Subscription> { $0.cancelledDate == nil },
        sort: \Subscription.name
    ) private var activeSubscriptions: [Subscription]

    @State private var showingEdit = false
    @State private var showingCancelConfirm = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        List {
            heroSection
            detailsSection
            if let card = subscription.card {
                cardSection(card)
            }
            if !subscription.notes.isEmpty {
                notesSection
            }
            costSection
            if subscription.isActive {
                actionsSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if subscription.isActive {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showingEdit = true }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            SubscriptionFormView(subscription: subscription)
        }
        .confirmationDialog(
            "Cancel \(subscription.name)?",
            isPresented: $showingCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Cancel Subscription", role: .destructive) {
                subscription.cancelledDate = .now
                NotificationService.shared.removeReminders(for: subscription)
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("This will mark the subscription as cancelled. You can still view it in your history.")
        }
        .confirmationDialog(
            "Delete \(subscription.name)?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(subscription)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the subscription and cannot be undone.")
        }
    }

    private var heroSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: subscription.category.icon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Color(hexString: subscription.category.color)
                            .opacity(subscription.isActive ? 1 : 0.4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title2.weight(.bold))

                    Text("per \(subscription.billingCycle.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if subscription.isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    } else {
                        Label("Cancelled", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            LabeledContent("Category") {
                HStack(spacing: 4) {
                    Image(systemName: subscription.category.icon)
                    Text(subscription.category.rawValue)
                }
                .foregroundStyle(Color(hexString: subscription.category.color))
            }

            LabeledContent("Started", value: subscription.startDate, format: .dateTime.month().day().year())

            if let next = subscription.nextRenewalDate {
                LabeledContent("Next Renewal") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(next, format: .dateTime.month().day().year())
                        Text(next, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let cancelled = subscription.cancelledDate {
                LabeledContent("Cancelled", value: cancelled, format: .dateTime.month().day().year())
            }
        }
    }

    private func cardSection(_ card: Card) -> some View {
        Section("Payment") {
            Label("\(card.name) ···· \(card.lastFourDigits)", systemImage: "creditcard")
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            Text(subscription.notes)
                .foregroundStyle(.secondary)
        }
    }

    private var costSection: some View {
        Section("Cost Breakdown") {
            LabeledContent(
                "Monthly",
                value: subscription.monthlyAmount,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
            LabeledContent(
                "Yearly",
                value: subscription.yearlyAmount,
                format: .currency(code: Locale.current.currency?.identifier ?? "USD")
            )
        }
    }

    private var actionsSection: some View {
        Section {
            Button(role: .destructive) {
                showingCancelConfirm = true
            } label: {
                Label("Cancel Subscription", systemImage: "xmark.circle")
            }

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }
}
