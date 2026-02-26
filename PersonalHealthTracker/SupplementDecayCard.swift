import SwiftUI
import Charts

struct SupplementDecayCard: View {
    let entry: SupplementEntry

    // Define “effectively out” as <1% remaining
    private let outThreshold = 0.01

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.name).font(.headline)
                Spacer()
                Text("\(format(entry.amount)) \(entry.unit)")
                    .foregroundStyle(.secondary)
            }

            Text("Taken \(entry.time.formatted(date: .omitted, time: .shortened)) • Half-life \(format(entry.halfLifeHours))h")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(points) { p in
                LineMark(
                    x: .value("Time", p.time),
                    y: .value("Remaining", p.remainingFraction)
                )
            }
            .chartYScale(domain: 0...1)
            .frame(height: 140)

            HStack(spacing: 12) {
                Text("50% @ \(halfLifeTime.formatted(date: .omitted, time: .shortened))")
                Spacer()
                Text("~out @ \(outTime.formatted(date: .omitted, time: .shortened))")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Build an exponential decay curve: remaining = 0.5^(t/halfLife)
    private var points: [DecayPoint] {
        let start = entry.time
        let end = outTime
        let minutesStep = 30

        var arr: [DecayPoint] = []
        var t = start
        while t <= end {
            let hours = t.timeIntervalSince(start) / 3600.0
            let remaining = pow(0.5, hours / entry.halfLifeHours)
            arr.append(DecayPoint(time: t, remainingFraction: remaining))
            t = Calendar.current.date(byAdding: .minute, value: minutesStep, to: t) ?? t.addingTimeInterval(1800)
        }
        return arr
    }

    private var halfLifeTime: Date {
        entry.time.addingTimeInterval(entry.halfLifeHours * 3600.0)
    }

    // time when remaining fraction drops below outThreshold
    private var outTime: Date {
        // Solve: outThreshold = 0.5^(t/HL)  =>  t = HL * log(outThreshold)/log(0.5)
        let tHours = entry.halfLifeHours * (log(outThreshold) / log(0.5))
        return entry.time.addingTimeInterval(tHours * 3600.0)
    }

    private func format(_ x: Double) -> String {
        x.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(x)) : String(format: "%.1f", x)
    }

    struct DecayPoint: Identifiable {
        let id = UUID()
        let time: Date
        let remainingFraction: Double
    }
}
