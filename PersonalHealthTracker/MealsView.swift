import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealEntry.time, order: .reverse)
    private var meals: [MealEntry]

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if meals.isEmpty {
                    ContentUnavailableView("No meals yet", systemImage: "fork.knife",
                                           description: Text("Tap + to add your first meal."))
                } else {
                    ForEach(meals) { meal in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(meal.name).font(.headline)
                                Spacer()
                                Text("\(meal.calories) cal")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("P \(meal.protein)g • C \(meal.carbs)g • F \(meal.fat)g")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(meal.time, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteMeals)
                }
            }
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddMealView()
            }
        }
    }

    private func deleteMeals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(meals[index])
        }
    }
}
