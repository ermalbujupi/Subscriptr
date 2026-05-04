import SwiftUI
import SwiftData

struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    @State private var showingAddSheet = false
    @State private var showCancelled = false
    @State private var searchText = ""
    @State private var selectedCategory: Category?

    private var displayed: [Subscription] {
        subscriptions.filter { sub in
            let passesActive = showCancelled ? true : sub.isActive
            let passesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let passesCategory = selectedCategory == nil || sub.category == selectedCategory
            return passesActive && passesSearch && passesCategory
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayed.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Subscriptions")
            .searchable(text: $searchText, prompt: "Search subscriptions")
            .toolbar { toolbar }
            .sheet(isPresented: $showingAddSheet) {
                SubscriptionFormView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            searchText.isEmpty ? "No Subscriptions" : "No Results",
            systemImage: searchText.isEmpty ? "plus.circle" : "magnifyingglass",
            description: Text(
                searchText.isEmpty
                    ? (showCancelled ? "Add your first subscription." : "No active subscriptions.")
                    : "Try a different search or filter."
            )
        )
    }

    private var list: some View {
        List {
            categoryFilterBar
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            ForEach(displayed) { subscription in
                NavigationLink(destination: SubscriptionDetailView(subscription: subscription)) {
                    SubscriptionListRow(subscription: subscription)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if subscription.isActive {
                        Button(role: .destructive) {
                            subscription.cancelledDate = .now
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                        .tint(.orange)
                    }
                    Button(role: .destructive) {
                        modelContext.delete(subscription)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(Category.allCases, id: \.self) { cat in
                    FilterChip(
                        label: cat.rawValue,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showCancelled.toggle()
            } label: {
                Image(systemName: showCancelled ? "eye.slash" : "eye")
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
}

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
