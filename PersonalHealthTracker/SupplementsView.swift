import SwiftUI
import SwiftData

struct SupplementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SupplementEntry.time, order: .reverse) private var entries: [SupplementEntry]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    ContentUnavailableView("No supplements yet",
                                           systemImage: "pills",
                                           description: Text("Tap + to add caffeine, ibuprofen, etc."))
                } else {
                    ForEach(entries) { s in
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
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSupplementView()
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { modelContext.delete(entries[i]) }
    }

    private func formatAmount(_ x: Double) -> String {
        x.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(x)) : String(format: "%.1f", x)
    }
}
