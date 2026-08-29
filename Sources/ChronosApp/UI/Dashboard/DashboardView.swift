import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case today
    case timeline
    case weekly
    case privacy
    case diagnostics

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .timeline: return "timeline.selection"
        case .weekly: return "chart.bar.xaxis"
        case .privacy: return "hand.raised"
        case .diagnostics: return "gauge.with.dots.needle.50percent"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var model: AppModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            NavigationSplitView {
                List(DashboardSection.allCases, selection: $model.dashboardSection) { section in
                    Label(section.title, systemImage: section.icon).tag(section)
                }
                .navigationTitle("CHRONOS")
                .frame(minWidth: 180)
            } detail: {
                Group {
                    switch model.dashboardSection {
                    case .today: TodayDashboardView(model: model)
                    case .timeline: TimelineView(model: model)
                    case .weekly: WeeklyDashboardView(model: model)
                    case .privacy: PrivacyView(model: model)
                    case .diagnostics: DiagnosticsView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            FirstRunView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.weight(.semibold))
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let icon: String
    var detail: String?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let detail { Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

func chronosDuration(_ seconds: TimeInterval) -> String {
    guard seconds >= 60 else { return "<1m" }
    let units: Set<Duration.UnitsFormatStyle.Unit> = seconds >= 3600
        ? [.hours, .minutes]
        : [.minutes]
    return Duration.seconds(seconds).formatted(.units(
        allowed: units,
        width: .abbreviated,
        maximumUnitCount: 2
    ))
}
