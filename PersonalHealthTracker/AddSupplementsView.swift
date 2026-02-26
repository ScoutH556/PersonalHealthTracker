import SwiftUI
import SwiftData

struct AddSupplementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selected = SupplementPresets.all.first!
    @State private var amountText = ""
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Supplement", selection: $selected) {
                        ForEach(SupplementPresets.all) { p in
                            Text(p.name).tag(p)
                        }
                    }
                }

                Section("Details") {
                    TextField("Amount (\(selected.defaultUnit))", text: $amountText)
                        .keyboardType(.decimalPad)

                    DatePicker("Time", selection: $time, displayedComponents: [.date, .hourAndMinute])

                    Text("Half-life: \(selected.halfLifeHours, specifier: "%.1f") hours")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Supplement")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                amountText = String(Int(selected.defaultAmount))
            }
            .onChange(of: selected) {
                amountText = String(Int(selected.defaultAmount))
            }
        }
    }

    private var canSave: Bool { Double(amountText) != nil }

    private func save() {
        let amount = Double(amountText) ?? selected.defaultAmount
        let entry = SupplementEntry(
            name: selected.name,
            amount: amount,
            unit: selected.defaultUnit,
            halfLifeHours: selected.halfLifeHours,
            time: time
        )
        modelContext.insert(entry)
        dismiss()
    }
}
