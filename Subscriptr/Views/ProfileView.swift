import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.name) private var cards: [Card]
    @Query(
        filter: #Predicate<Subscription> { $0.cancelledDate == nil },
        sort: \Subscription.name
    ) private var activeSubscriptions: [Subscription]

    @AppStorage("currencyCode") private var currencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("userName") private var userName = ""

    @State private var showingAddCard = false
    @State private var showingCurrencyPicker = false
    @State private var editingName = false
    @State private var nameInput = ""

    var body: some View {
        NavigationStack {
            List {
                profileHeader

                Section("Cards") {
                    ForEach(cards) { card in
                        CardRow(card: card, subscriptionCount: subscriptionCount(for: card))
                    }
                    .onDelete(perform: deleteCards)

                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Add Card", systemImage: "plus.circle")
                    }
                }

                Section("Preferences") {
                    HStack {
                        Label("Currency", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(currencyCode)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showingCurrencyPicker = true }
                }

                Section("Summary") {
                    LabeledContent("Active Subscriptions", value: "\(activeSubscriptions.count)")
                    LabeledContent("Total Cards", value: "\(cards.count)")
                    LabeledContent(
                        "Monthly Spend",
                        value: activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount },
                        format: .currency(code: currencyCode)
                    )
                }

                Section {
                    Text("Subscriptr v1.0")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                CurrencyPickerView(current: currencyCode) { code in
                    currencyCode = code
                }
            }
            .alert("Your Name", isPresented: $editingName) {
                TextField("Name", text: $nameInput)
                Button("Save") { userName = nameInput }
                Button("Cancel", role: .cancel) { nameInput = userName }
            }
        }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.gradient)
                        .frame(width: 60, height: 60)
                    Text(initials)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(userName.isEmpty ? "Tap to set name" : userName)
                        .font(.headline)
                        .foregroundStyle(userName.isEmpty ? .secondary : .primary)
                    Text("Subscription Tracker")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    nameInput = userName
                    editingName = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var initials: String {
        let parts = userName.split(separator: " ").prefix(2)
        guard !parts.isEmpty else { return "?" }
        return parts.compactMap(\.first).map(String.init).joined()
    }

    private func subscriptionCount(for card: Card) -> Int {
        activeSubscriptions.filter { $0.card?.persistentModelID == card.persistentModelID }.count
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cards[index])
        }
    }
}

struct CardRow: View {
    let card: Card
    let subscriptionCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.body.weight(.medium))
                Text("···· \(card.lastFourDigits)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(subscriptionCount) sub\(subscriptionCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CurrencyPickerView: View {
    let current: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let common = ["USD", "EUR", "GBP", "CHF", "CAD", "AUD", "JPY", "CNY", "INR", "BRL"]
    @State private var search = ""

    private var filtered: [String] {
        let all = Locale.commonISOCurrencyCodes
        let results: [String] = search.isEmpty ? all : all.filter { $0.localizedCaseInsensitiveContains(search) }
        return results.sorted { a, b in
            let aCommon = common.contains(a)
            let bCommon = common.contains(b)
            if aCommon != bCommon { return aCommon }
            return a < b
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered, id: \.self) { (code: String) in
                    currencyRow(code: code)
                }
            }
            .searchable(text: $search, prompt: "Search currency")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func currencyRow(code: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(code)
                    .font(.body.weight(.medium))
                if let name = Locale.current.localizedString(forCurrencyCode: code) {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if code == current {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(code)
            dismiss()
        }
    }
}
