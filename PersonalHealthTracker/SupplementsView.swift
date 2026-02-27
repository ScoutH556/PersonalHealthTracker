import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementEntry.time, order: .reverse) private var allEntries: [SupplementEntry]
    @State private var showingAdd = false
    @State private var selectedDate: Date = Date()
    @State private var showingDayPicker = false

    var body: some View {
        NavigationStack {
            List {
                if dayEntries.isEmpty {
                    ContentUnavailableView(
                        "No supplements for \(dayLabel)",
                        systemImage: "pills",
                        description: Text("Tap + to add caffeine, ibuprofen, etc.")
                    )
                } else {
                    ForEach(dayEntries) { s in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(s.name).font(.headline)
                                Spacer()
                                Text("\(formatAmount(s.amount)) \(s.unit)")
                                    .foregroundStyle(.secondary)
                            }
                            Text("Half-life: \(formatAmount(s.halfLifeHours)) h")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(s.time, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Supplements")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingDayPicker = true } label: { Image(systemName: "calendar") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSupplementView()
            }
            .sheet(isPresented: $showingDayPicker) {
                DayPickerSheet(selectedDate: $selectedDate)
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let entries = dayEntries
        for i in offsets { modelContext.delete(entries[i]) }
    }

    private func formatAmount(_ x: Double) -> String {
        x.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(x)) : String(format: "%.1f", x)
    }

    private var dayEntries: [SupplementEntry] {
        allEntries.filter { isInSelectedDay($0.time) }
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
