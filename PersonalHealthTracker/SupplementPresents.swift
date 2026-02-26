import Foundation

struct SupplementPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let defaultUnit: String
    let defaultAmount: Double
    let halfLifeHours: Double
}

enum SupplementPresets {
    // Choose “typical” values (you can change later per your preference)
    static let all: [SupplementPreset] = [
        SupplementPreset(name: "Caffeine",     defaultUnit: "mg", defaultAmount: 100, halfLifeHours: 5.0),
        SupplementPreset(name: "Ibuprofen",    defaultUnit: "mg", defaultAmount: 200, halfLifeHours: 2.0),
        SupplementPreset(name: "Astaxanthin",  defaultUnit: "mg", defaultAmount: 12,  halfLifeHours: 21.0)
    ]
}
