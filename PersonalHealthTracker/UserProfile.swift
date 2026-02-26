import Foundation
import SwiftData

@Model
final class UserProfile {
    var heightFeet: Int
    var heightInches: Int
    var weightLbs: Double
    var sex: Sex
    var usesOralContraceptives: Bool
    var smoker: Bool

    init(heightFeet: Int = 5,
         heightInches: Int = 3,
         weightLbs: Double = 118,
         sex: Sex = .female,
         usesOralContraceptives: Bool = false,
         smoker: Bool = false) {
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weightLbs = weightLbs
        self.sex = sex
        self.usesOralContraceptives = usesOralContraceptives
        self.smoker = smoker
    }
}

enum Sex: String, CaseIterable, Codable {
    case female, male, other
}
