import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealEntry.time, order: .reverse)
    private var allMeals: [MealEntry]

    @State private var showingAdd = false
    @State private var selectedDate: Date = Date()
    @State private var showingDayPicker = false

    var body: some View {
        NavigationStack {
            List {
                if dayMeals.isEmpty {
                    ContentUnavailableView(
                        "No meals for \(dayLabel)",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add a meal for this day.")
                    )
                } else {
                    ForEach(dayMeals) { meal in
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
                    Button { showingDayPicker = true } label: { Image(systemName: "calendar") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddMealView()
            }
            .sheet(isPresented: $showingDayPicker) {
                DayPickerSheet(selectedDate: $selectedDate)
            }
        }
    }

    private func deleteMeals(at offsets: IndexSet) {
        let meals = dayMeals
        for index in offsets {
            modelContext.delete(meals[index])
        }
    }

    private var dayMeals: [MealEntry] {
        allMeals.filter { isInSelectedDay($0.time) }
    }

    private var dayLabel: String {
        Calendar.current.isDateInToday(selectedDate)
            ? "Today"
            : selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var dayRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: selectedDate)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        return (start, end)
    }

    private func isInSelectedDay(_ date: Date) -> Bool {
        let r = dayRange
        return date >= r.start && date < r.end
    }
}
