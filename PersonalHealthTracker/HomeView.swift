import SwiftUI
import SwiftData
import Charts

struct HomeView: View {

    // SwiftData queries
    @Query private var meals: [MealEntry]
    @Query private var supplements: [SupplementEntry]
    @Query private var profiles: [UserProfile]

    // Health manager (Observation system)
    @State private var health = HealthManager()

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    Text("Today")
                        .font(.largeTitle)
                        .bold()

                    // MARK: Steps (HealthKit)
                    Button {
                        Task {
                            await health.requestAuthorizationAndFetchSteps()
                        }
                    } label: {
                        metricCard(
                            title: "Steps",
                            value: stepsText,
                            subtitle: "today"
                        )
                    }
                    .buttonStyle(.plain)

                    // MARK: Nutrition
                    metricCard(title: "Calories", value: "\(todayCalories)", subtitle: "so far")
                    metricCard(title: "Protein", value: "\(todayProtein) g", subtitle: "so far")
                    metricCard(title: "Carbs", value: "\(todayCarbs) g", subtitle: "so far")
                    metricCard(title: "Fat", value: "\(todayFat) g", subtitle: "so far")

                    // MARK: Caffeine
                    metricCard(
                        title: "Caffeine active",
                        value: "\(Int(caffeineRemainingNowMg)) mg",
                        subtitle: "estimated right now"
                    )

                    Divider().padding(.vertical, 8)

                    Text("Supplements")
                        .font(.title2)
                        .bold()

                    if todaySupplements.isEmpty {
                        Text("No supplements logged today.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todaySupplements) { s in
                            SupplementDecayCard(entry: s)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Home")
        }
        .task {
            await health.requestAuthorizationAndFetchSteps()
        }
    }

    // MARK: Steps display
    private var stepsText: String {

        if !health.isHealthAvailable {
            return "Unavailable"
        }

        if !health.isAuthorized {
            return "Tap to enable"
        }

        if let steps = health.stepsToday {
            return "\(steps)"
        }

        return "—"
    }

    // MARK: Meals (today)
    private var todayMeals: [MealEntry] {
        meals.filter { Calendar.current.isDateInToday($0.time) }
    }

    private var todayCalories: Int { todayMeals.reduce(0) { $0 + $1.calories } }
    private var todayProtein: Int  { todayMeals.reduce(0) { $0 + $1.protein } }
    private var todayCarbs: Int    { todayMeals.reduce(0) { $0 + $1.carbs } }
    private var todayFat: Int      { todayMeals.reduce(0) { $0 + $1.fat } }

    // MARK: Supplements (today)
    private var todaySupplements: [SupplementEntry] {
        supplements
            .filter { Calendar.current.isDateInToday($0.time) }
            .sorted { $0.time > $1.time }
    }

    // MARK: Profile
    private var profile: UserProfile? {
        profiles.first
    }

    // MARK: Caffeine remaining
    private var todayCaffeineDoses: [SupplementEntry] {
        supplements.filter {
            Calendar.current.isDateInToday($0.time) &&
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "caffeine"
        }
    }

    private var caffeineRemainingNowMg: Double {

        guard let p = profile else { return 0 }

        let halfLife = CaffeineCalculator.estimatedHalfLifeHours(profile: p)
        let now = Date()

        return todayCaffeineDoses.reduce(0) { sum, entry in

            sum + CaffeineCalculator.remainingAmountMg(
                doseMg: entry.amount,
                takenAt: entry.time,
                now: now,
                halfLifeHours: halfLife
            )
        }
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
