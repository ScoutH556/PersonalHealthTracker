import SwiftUI
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthManager {
    private let store = HKHealthStore()

    var stepsForSelectedDay: Int? = nil
    var isAuthorized: Bool = false

    var isHealthAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorizationAndFetchSteps(for date: Date) async {
        guard isHealthAvailable else {
            stepsForSelectedDay = nil
            isAuthorized = false
            return
        }

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            stepsForSelectedDay = nil
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            isAuthorized = true
            await fetchSteps(for: date)
        } catch {
            isAuthorized = false
            stepsForSelectedDay = nil
            print("Health authorization error:", error)
        }
    }

    func fetchSteps(for date: Date) async {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86400)
        let now = Date()

        if startOfDay > now {
            stepsForSelectedDay = nil
            return
        }

        let queryEnd = min(endOfDay, now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: queryEnd, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            guard let self else { return }

            if let error {
                print("Steps query error:", error)
                Task { @MainActor in self.stepsForSelectedDay = nil }
                return
            }

            let sum = result?.sumQuantity()
            let steps = sum?.doubleValue(for: HKUnit.count()) ?? 0

            Task { @MainActor in
                self.stepsForSelectedDay = Int(steps)
            }
        }

        store.execute(query)
    }
}
