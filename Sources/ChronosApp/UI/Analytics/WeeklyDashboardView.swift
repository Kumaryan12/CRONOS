import Charts
import SwiftUI

struct WeeklyDashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: "Weekly", subtitle: weekLabel)

                HStack(spacing: 12) {
                    MetricCard(title: "ACTIVE", value: chronosDuration(model.weeklyAnalytics.totalActiveDuration), icon: "clock")
                    MetricCard(title: "PRODUCTIVE", value: chronosDuration(model.weeklyAnalytics.totalProductiveDuration), icon: "hammer")
                    MetricCard(title: "FOCUS", value: chronosDuration(model.weeklyAnalytics.totalFocusDuration), icon: "scope")
                    MetricCard(title: "AVG SCORE", value: model.weeklyAnalytics.averageFocusScore.map { String(Int($0.rounded())) } ?? "—", icon: "chart.line.uptrend.xyaxis")
                    MetricCard(title: "SWITCHES", value: "\(model.weeklyAnalytics.totalContextSwitches)", icon: "arrow.left.arrow.right")
                }

                GroupBox("Productive time by day") {
                    Chart(model.weeklyAnalytics.days) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Hours", day.productiveDuration / 3600)
                        )
                        .foregroundStyle(.blue)
                    }
                    .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) } }
                    .chartYAxisLabel("hours")
                    .frame(height: 220)
                    .padding(.vertical, 8)
                }

                HStack(alignment: .top, spacing: 16) {
                    GroupBox("Best day") {
                        if let day = model.weeklyAnalytics.mostProductiveDay, day.productiveDuration > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(day.date.formatted(.dateTime.weekday(.wide))).font(.title3.weight(.semibold))
                                Text("\(chronosDuration(day.productiveDuration)) productive")
                                Text("Focus score \(day.focusScore.map(String.init) ?? "—")").foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("More history is needed.").foregroundStyle(.secondary)
                        }
                    }

                    GroupBox("Compared with prior 14 days") {
                        if let baseline = model.weeklyAnalytics.baseline {
                            VStack(alignment: .leading, spacing: 8) {
                                comparison("Productive/day", seconds: baseline.productiveDifference)
                                comparison("Distraction/day", seconds: baseline.distractionDifference)
                                Text("Sample: \(baseline.sampleSize) active days").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("A baseline appears after several active days.").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private var weekLabel: String {
        let interval = model.weeklyAnalytics.interval
        return "\(interval.start.formatted(date: .abbreviated, time: .omitted)) – \(interval.end.addingTimeInterval(-1).formatted(date: .abbreviated, time: .omitted))"
    }

    private func comparison(_ label: String, seconds: TimeInterval) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(seconds >= 0 ? "+" : "−")\(chronosDuration(abs(seconds)))")
                .monospacedDigit()
                .foregroundStyle(seconds >= 0 ? .green : .secondary)
        }
    }
}
