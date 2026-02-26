import Foundation
import SwiftData

@Model
final class MealEntry {
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var time: Date

    init(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, time: Date) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.time = time
    }
}
