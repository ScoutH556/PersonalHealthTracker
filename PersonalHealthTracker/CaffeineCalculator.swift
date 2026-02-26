import Foundation

enum CaffeineCalculator {

    static func remainingAmountMg(doseMg: Double, takenAt: Date, now: Date, halfLifeHours: Double) -> Double {
        let hours = max(0, now.timeIntervalSince(takenAt) / 3600.0)
        let remainingFraction = pow(0.5, hours / max(0.1, halfLifeHours))
        return doseMg * remainingFraction
    }

    /// Simple derived half-life estimate (transparent rules):
    /// - Starts at 5 hours (common average)
    /// - Oral contraceptives: slower clearance → longer half-life
    /// - Smoking: faster clearance → shorter half-life
    static func estimatedHalfLifeHours(profile: UserProfile) -> Double {
        var hl = 5.0

        if profile.usesOralContraceptives { hl *= 2.0 }
        if profile.smoker { hl *= 0.5 }

        // Keep within a reasonable range
        return min(max(hl, 1.5), 16.0)
    }
}
