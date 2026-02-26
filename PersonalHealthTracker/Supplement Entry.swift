import Foundation
import SwiftData

@Model
final class SupplementEntry {
    var name: String
    var amount: Double          // mg (or units you decide)
    var unit: String            // "mg", etc.
    var halfLifeHours: Double   // used for decay curve
    var time: Date

    init(name: String, amount: Double, unit: String, halfLifeHours: Double, time: Date) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.halfLifeHours = halfLifeHours
        self.time = time
    }
}
