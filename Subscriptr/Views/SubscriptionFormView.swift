import SwiftUI
import SwiftData

struct SubscriptionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Card.name) private var cards: [Card]

    var subscription: Subscription?

    @State private var name = ""
    @State private var amount = ""
    @State private var billingCycle = BillingCycle.monthly
    @State private var startDate = Date()
    @State private var category = Category.other
    @State private var notes = ""
    @State private var selectedCard: Card?
    @State private var showingAddCard = false

    private var isEditing: Bool { subscription != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount != nil }
    private var parsedAmount: Double? { Double(amount.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Netflix)", text: $name)

                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Billing Cycle", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Payment") {
                    if cards.isEmpty {
                        Button("Add a Card") { showingAddCard = true }
                    } else {
                        Picker("Card", selection: $selectedCard) {
                            Text("None").tag(Optional<Card>.none)
                            ForEach(cards) { card in
                                Text("\(card.name) ···\(card.lastFourDigits)").tag(Optional(card))
                            }
                        }
                        Button("Add New Card") { showingAddCard = true }
                            .font(.footnote)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if isEditing {
                    Section {
                        monthlyCostRow
                        yearlyCostRow
                    } header: {
                        Text("Estimated Cost")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Subscription" : "Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
            .onAppear { populate() }
        }
    }

    private var monthlyCostRow: some View {
        HStack {
            Text("Monthly")
            Spacer()
            if let amount = parsedAmount {
                let monthly = amount * billingCycle.monthlyMultiplier
                Text(monthly, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var yearlyCostRow: some View {
        HStack {
            Text("Yearly")
            Spacer()
            if let amount = parsedAmount {
                let yearly = amount * billingCycle.yearlyMultiplier
                Text(yearly, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func populate() {
        guard let sub = subscription else { return }
        name = sub.name
        amount = String(sub.amount)
        billingCycle = sub.billingCycle
        startDate = sub.startDate
        category = sub.category
        notes = sub.notes
        selectedCard = sub.card
    }

    private func save() {
        guard let amt = parsedAmount else { return }
        if let sub = subscription {
            sub.name = name.trimmingCharacters(in: .whitespaces)
            sub.amount = amt
            sub.billingCycle = billingCycle
            sub.startDate = startDate
            sub.category = category
            sub.notes = notes
            sub.card = selectedCard
        } else {
            let sub = Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                amount: amt,
                billingCycle: billingCycle,
                startDate: startDate,
                category: category,
                notes: notes,
                card: selectedCard
            )
            modelContext.insert(sub)
        }
        dismiss()
    }
}
