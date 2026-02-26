import SwiftUI
import SwiftData

struct AppsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppOpenLog.time, order: .reverse) private var logs: [AppOpenLog]

    // For an estimated "time away" measurement
    @State private var launchedAppAt: Date? = nil
    @State private var lastLaunchedAppName: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Quick Launch") {
                    appRow(
                        name: "Instagram",
                        icon: "camera",
                        scheme: "instagram://app",
                        web: "https://www.instagram.com"
                    )

                    appRow(
                        name: "Snapchat",
                        icon: "message",
                        scheme: "snapchat://",
                        web: "https://www.snapchat.com"
                    )
                }

                Section("Today") {
                    statRow("Instagram opens", countToday("Instagram"))
                    statRow("Snapchat opens", countToday("Snapchat"))

                    if let estimate = estimatedTimeAwayText {
                        HStack {
                            Text("Last session away")
                            Spacer()
                            Text(estimate)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        resetToday()
                    } label: {
                        Text("Reset today’s opens")
                    }
                }

                Section("Recent Opens") {
                    if logs.isEmpty {
                        Text("No opens logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logs.prefix(30)) { log in
                            HStack {
                                Text(log.appName)
                                Spacer()
                                Text(log.time.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Apps")
        }
        // When your app becomes active again, estimate how long you were away
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard let start = launchedAppAt, let app = lastLaunchedAppName else { return }
            let secondsAway = Date().timeIntervalSince(start)

            // Save an *estimated* time-away record as another log entry (optional)
            // For now we just store it in-memory and show it on screen
            _lastAwaySeconds = secondsAway
            _lastAwayApp = app

            launchedAppAt = nil
            lastLaunchedAppName = nil
        }
    }

    // MARK: - Row builder
    @ViewBuilder
    private func appRow(name: String, icon: String, scheme: String, web: String) -> some View {
        Button {
            logOpen(name)
            launchedAppAt = Date()
            lastLaunchedAppName = name
            openExternalApp(scheme: scheme, web: web)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open \(name)")
                    Text("Opened today: \(countToday(name))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Logging
    private func logOpen(_ appName: String) {
        modelContext.insert(AppOpenLog(appName: appName, time: Date()))
        do { try modelContext.save() } catch { print("Save error:", error) }
    }

    // MARK: - Open app / fallback to web
    private func openExternalApp(scheme: String, web: String) {
        let schemeURL = URL(string: scheme)
        let webURL = URL(string: web)

        if let schemeURL, UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL)
        } else if let webURL {
            UIApplication.shared.open(webURL)
        }
    }

    // MARK: - Today counts + reset
    private func countToday(_ app: String) -> Int {
        let cal = Calendar.current
        return logs.filter { $0.appName == app && cal.isDateInToday($0.time) }.count
    }

    private func resetToday() {
        let cal = Calendar.current
        for log in logs where cal.isDateInToday(log.time) {
            modelContext.delete(log)
        }
        do { try modelContext.save() } catch { print("Delete error:", error) }
    }

    // MARK: - Estimated "time away"
    @State private var _lastAwaySeconds: TimeInterval? = nil
    @State private var _lastAwayApp: String? = nil

    private var estimatedTimeAwayText: String? {
        guard let s = _lastAwaySeconds, let app = _lastAwayApp else { return nil }
        let mins = Int(s) / 60
        let secs = Int(s) % 60
        if mins > 0 { return "\(mins)m \(secs)s (after \(app))" }
        return "\(secs)s (after \(app))"
    }
}
