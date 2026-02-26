import SwiftUI
import SwiftData
import Charts

struct HomeView: View {

    // SwiftData queries
    @Query private var meals: [MealEntry]
    @Query private var supplements: [SupplementEntry]
    @Query private var profiles: [UserProfile]

    // Health manager
    @State private var health = HealthManager()

    // Date selection
    @State private var selectedDate: Date = Date()
    @State private var showingDayPicker = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    Text(dayTitle)
                        .font(.largeTitle)
                        .bold()

                    // MARK: Steps (only meaningful for "today" with your current HealthManager)
                    Button {
                        Task { await health.requestAuthorizationAndFetchSteps() }
                    } label: {
                        metricCard(
                            title: "Steps",
                            value: stepsText,
                            subtitle: stepsSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(isSelectedDayToday ? 1 : 0.6)

                    // MARK: Nutrition
                    metricCard(title: "Calories", value: "\(dayCalories)", subtitle: "so far")
                    metricCard(title: "Protein", value: "\(dayProtein) g", subtitle: "so far")
                    metricCard(title: "Carbs", value: "\(dayCarbs) g", subtitle: "so far")
                    metricCard(title: "Fat", value: "\(dayFat) g", subtitle: "so far")

                    // MARK: Caffeine
                    metricCard(
                        title: "Caffeine in system",
                        value: "\(Int(caffeineRemainingNowMg)) mg",
                        subtitle: "est. ~0 at \(caffeineZeroTimeText)"
                    )
                    Divider().padding(.vertical, 8)

                    Text("Supplements")
                        .font(.title2)
                        .bold()

                    if daySupplements.isEmpty {
                        Text("No supplements logged for this day.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(daySupplements) { s in
                            SupplementDecayCard(entry: s)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingDayPicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingDayPicker) {
                DayPickerSheet(selectedDate: $selectedDate)
            }
        }
        .task {
            // Only fetch steps for today (your HealthManager is "today" scoped)
            await health.requestAuthorizationAndFetchSteps()
        }
    }

    // MARK: Date helpers
    private var isSelectedDayToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var dayTitle: String {
        if isSelectedDayToday { return "Today" }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
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

    // MARK: Steps display
    private var stepsText: String {
        guard isSelectedDayToday else { return "—" }

        if !health.isHealthAvailable { return "Unavailable" }
        if !health.isAuthorized { return "Tap to enable" }
        if let steps = health.stepsToday { return "\(steps)" }
        return "—"
    }

    private var stepsSubtitle: String {
        isSelectedDayToday ? "today" : "only available for today"
    }

    // MARK: Meals (selected day)
    private var dayMeals: [MealEntry] {
        meals.filter { isInSelectedDay($0.time) }
    }

    private var dayCalories: Int { dayMeals.reduce(0) { $0 + $1.calories } }
    private var dayProtein: Int  { dayMeals.reduce(0) { $0 + $1.protein } }
    private var dayCarbs: Int    { dayMeals.reduce(0) { $0 + $1.carbs } }
    private var dayFat: Int      { dayMeals.reduce(0) { $0 + $1.fat } }

    // MARK: Supplements (selected day)
    private var daySupplements: [SupplementEntry] {
        supplements
            .filter { isInSelectedDay($0.time) }
            .sorted { $0.time > $1.time }
    }

    // MARK: Profile
    private var profile: UserProfile? {
        profiles.first
    }

    // MARK: Caffeine remaining
    private var dayCaffeineDoses: [SupplementEntry] {
        supplements.filter {
            isInSelectedDay($0.time) &&
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "caffeine"
        }
    }

    private var caffeineRemainingNowMg: Double {
        guard let p = profile else { return 0 }

        // For past days, "remaining now" isn't super meaningful, but this still computes decay to the current time.
        let halfLife = CaffeineCalculator.estimatedHalfLifeHours(profile: p)
        let now = Date()

        return dayCaffeineDoses.reduce(0) { sum, entry in
            sum + CaffeineCalculator.remainingAmountMg(
                doseMg: entry.amount,
                takenAt: entry.time,
                now: now,
                halfLifeHours: halfLife
            )
        }
    }
    // Treat "0" as below this threshold (mg)
    private let caffeineZeroThresholdMg: Double = 1.0

    private var estimatedCaffeineZeroTime: Date? {
        guard let p = profile else { return nil }
        guard !dayCaffeineDoses.isEmpty else { return nil }

        let halfLife = CaffeineCalculator.estimatedHalfLifeHours(profile: p)
        let now = Date()

        // After ~10 half-lives, a dose is basically gone (<0.1%)
        let lastDoseTime = dayCaffeineDoses.map(\.time).max() ?? now
        let upperBound = lastDoseTime.addingTimeInterval(halfLife * 3600 * 10)

        // If it's already ~0, return now
        if caffeineRemaining(at: now, halfLifeHours: halfLife) <= caffeineZeroThresholdMg {
            return now
        }

        // Binary search for time when remaining <= threshold
        var lo = now
        var hi = max(upperBound, now.addingTimeInterval(3600)) // at least 1 hour

        // Ensure hi is truly below threshold (expand if needed)
        var guardCount = 0
        while caffeineRemaining(at: hi, halfLifeHours: halfLife) > caffeineZeroThresholdMg, guardCount < 10 {
            hi = hi.addingTimeInterval(halfLife * 3600 * 5) // extend window
            guardCount += 1
        }

        // If still not below threshold, just give up safely
        if caffeineRemaining(at: hi, halfLifeHours: halfLife) > caffeineZeroThresholdMg {
            return nil
        }

        // 40 iterations is plenty precise (sub-second)
        for _ in 0..<40 {
            let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
            if caffeineRemaining(at: mid, halfLifeHours: halfLife) <= caffeineZeroThresholdMg {
                hi = mid
            } else {
                lo = mid
            }
        }

        return hi
    }

    private func caffeineRemaining(at time: Date, halfLifeHours: Double) -> Double {
        dayCaffeineDoses.reduce(0) { sum, entry in
            sum + CaffeineCalculator.remainingAmountMg(
                doseMg: entry.amount,
                takenAt: entry.time,
                now: time,
                halfLifeHours: halfLifeHours
            )
        }
    }

    private var caffeineZeroTimeText: String {
        guard let t = estimatedCaffeineZeroTime else { return "—" }
        if Calendar.current.isDateInToday(t) {
            return t.formatted(date: .omitted, time: .shortened)
        } else {
            return t.formatted(date: .abbreviated, time: .shortened)
        }
    }
    
    private var caffeineSubtitle: String {
        isSelectedDayToday ? "estimated right now" : "decayed to now"
    }

    // MARK: Card UI
    @ViewBuilder
    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 34, weight: .bold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
