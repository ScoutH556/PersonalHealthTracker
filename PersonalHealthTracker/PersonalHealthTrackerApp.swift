import SwiftUI
import SwiftData

@main
struct PersonalTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            MealEntry.self,
            SupplementEntry.self,
            UserProfile.self,
            AppOpenLog.self
        ])
    }
}
