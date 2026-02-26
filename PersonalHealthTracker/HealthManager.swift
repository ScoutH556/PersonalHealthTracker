import SwiftUI
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthManager {
    private let store = HKHealthStore()

    var stepsToday: Int? = nil
    var isAuthorized: Bool = false

    var isHealthAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorizationAndFetchSteps() async {
        guard isHealthAvailable else {
            stepsToday = nil
            isAuthorized = false
            return
        }

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            stepsToday = nil
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            isAuthorized = true
            await fetchStepsToday()
        } catch {
            isAuthorized = false
            stepsToday = nil
            print("Health authorization error:", error)
        }
    }

    func fetchStepsToday() async {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            guard let self else { return }

            if let error {
                print("Steps query error:", error)
                Task { @MainActor in self.stepsToday = nil }
                return
            }

            let sum = result?.sumQuantity()
            let steps = sum?.doubleValue(for: HKUnit.count()) ?? 0

            Task { @MainActor in
                self.stepsToday = Int(steps)
            }
        }

        store.execute(query)
    }
}
