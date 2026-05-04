import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var lastFour = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && lastFour.count == 4
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Card Name (e.g. Visa, Amex)", text: $name)
                    TextField("Last 4 digits", text: $lastFour)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFour) { _, new in
                            lastFour = String(new.filter(\.isNumber).prefix(4))
                        }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let card = Card(
            name: name.trimmingCharacters(in: .whitespaces),
            lastFourDigits: lastFour
        )
        modelContext.insert(card)
        dismiss()
    }
}
