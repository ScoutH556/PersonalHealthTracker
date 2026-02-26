import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Name (e.g., Greek yogurt bowl)", text: $name)

                    DatePicker("Time", selection: $time, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Nutrition") {
                    TextField("Calories", text: $caloriesText).keyboardType(.numberPad)
                    TextField("Protein (g)", text: $proteinText).keyboardType(.numberPad)
                    TextField("Carbs (g)", text: $carbsText).keyboardType(.numberPad)
                    TextField("Fat (g)", text: $fatText).keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMeal() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && Int(caloriesText) != nil
    }

    private func saveMeal() {
        let meal = MealEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: Int(caloriesText) ?? 0,
            protein: Int(proteinText) ?? 0,
            carbs: Int(carbsText) ?? 0,
            fat: Int(fatText) ?? 0,
            time: time
        )

        modelContext.insert(meal)
        dismiss()
    }
}
