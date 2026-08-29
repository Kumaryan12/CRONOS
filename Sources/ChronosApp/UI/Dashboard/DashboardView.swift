import Charts
import ChronosCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            dashboard
        } else {
            FirstRunView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .frame(minWidth: 760, minHeight: 520)
        }
    }

    private var dashboard: some View {
        NavigationSplitView {
            List {
                Label("Today", systemImage: "sun.max")
                Label("Timeline", systemImage: "timeline.selection")
                Label("Weekly", systemImage: "chart.bar.xaxis")
                Label("Settings", systemImage: "gearshape")
            }
            .navigationTitle("CHRONOS")
        } detail: {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Time Intelligence")
                        .font(.largeTitle.weight(.semibold))
                    Text("Understand where your time actually goes.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    metricCard("ACTIVE", duration(model.dailyAnalytics.activeDuration), "clock")
                    metricCard("PRODUCTIVE", duration(model.dailyAnalytics.productiveDuration), "hammer")
                    metricCard("DISTRACTION", duration(model.dailyAnalytics.distractionDuration), "sparkles.tv")
                    metricCard("FOCUS SCORE", model.dailyAnalytics.focusScore.map { "\($0.score)" } ?? "—", "scope")
                    metricCard("SWITCHES", "\(model.dailyAnalytics.contextSwitches)", "arrow.left.arrow.right")
                }

                GroupBox("Collector status") {
                    Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 12) {
                        GridRow { Text("Application"); Text(model.snapshot.currentApplication ?? "None") }
                        GridRow { Text("Idle"); Text(model.snapshot.isIdle ? "Yes" : "No") }
                        GridRow { Text("Screen"); Text(model.snapshot.isScreenAwake ? "Awake" : "Asleep") }
                        GridRow { Text("Tracking"); Text(model.snapshot.isTracking ? "Active" : "Paused") }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                if let persistenceError = model.persistenceError {
                    Label(persistenceError, systemImage: "externaldrive.badge.exclamationmark")
                        .foregroundStyle(.red)
                }

                if !model.dailyAnalytics.categories.isEmpty {
                    GroupBox("Where today went") {
                        Chart(model.dailyAnalytics.categories.prefix(7)) { item in
                            BarMark(
                                x: .value("Hours", item.duration / 3600),
                                y: .value("Category", item.category.name)
                            )
                            .foregroundStyle(color(for: item.category.classification))
                        }
                        .chartXAxisLabel("hours")
                        .frame(height: 180)
                        .padding(.vertical, 8)
                    }
                }

                Text("Recent completed sessions")
                    .font(.headline)
                List(model.recentSessions) { session in
                    HStack {
                        Text(session.applicationName)
                        Spacer()
                        Text(Duration.seconds(session.duration).formatted(
                            .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated)
                        ))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(28)
        }
    }

    private func metricCard(_ title: String, _ value: String, _ systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let units: Set<Duration.UnitsFormatStyle.Unit> = seconds >= 3600
            ? [.hours, .minutes]
            : [.minutes]
        return Duration.seconds(seconds).formatted(.units(
            allowed: units,
            width: .abbreviated,
            maximumUnitCount: 2
        ))
    }

    private func color(for classification: CategoryClassification) -> Color {
        switch classification {
        case .productive: return .blue
        case .neutral: return .gray
        case .distraction: return .orange
        case .other: return .secondary
        }
    }
}
