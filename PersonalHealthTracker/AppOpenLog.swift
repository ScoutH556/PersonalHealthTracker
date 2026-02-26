import Foundation
import SwiftData

@Model
final class AppOpenLog {
    var appName: String
    var time: Date

    init(appName: String, time: Date = Date()) {
        self.appName = appName
        self.time = time
    }
}
