import Charts
import ChronosCore
import SwiftUI

struct TodayDashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(
                    title: "Today",
                    subtitle: "Understand where your time actually goes."
                )

                HStack(spacing: 12) {
                    MetricCard(title: "ACTIVE", value: chronosDuration(model.dailyAnalytics.activeDuration), icon: "clock")
                    MetricCard(title: "PRODUCTIVE", value: chronosDuration(model.dailyAnalytics.productiveDuration), icon: "hammer")
                    MetricCard(title: "DISTRACTION", value: chronosDuration(model.dailyAnalytics.distractionDuration), icon: "sparkles.tv")
                    MetricCard(title: "FOCUS SCORE", value: model.dailyAnalytics.focusScore.map { "\($0.score)" } ?? "—", icon: "scope")
                    MetricCard(title: "SWITCHES", value: "\(model.dailyAnalytics.contextSwitches)", icon: "arrow.left.arrow.right")
                }

                if let error = model.persistenceError {
                    Label(error, systemImage: "externaldrive.badge.exclamationmark")
                        .foregroundStyle(.red)
                }

                if model.dailyAnalytics.categories.isEmpty {
                    EmptyStateView(
                        title: "No completed activity yet",
                        icon: "clock",
                        detail: "Chronos will summarize activity after the first application switch or idle boundary."
                    )
                    .frame(height: 220)
                } else {
                    GroupBox("Category allocation") {
                        Chart(model.dailyAnalytics.categories.prefix(7)) { item in
                            BarMark(
                                x: .value("Hours", item.duration / 3600),
                                y: .value("Category", item.category.name)
                            )
                            .foregroundStyle(ChronosColor.color(for: item.category.classification))
                        }
                        .chartXAxisLabel("hours")
                        .frame(height: 190)
                        .padding(.vertical, 8)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    GroupBox("Focus sessions") {
                        VStack(alignment: .leading, spacing: 10) {
                            if model.dailyAnalytics.focusSessions.isEmpty {
                                Text("No qualifying focus session yet.").foregroundStyle(.secondary)
                            }
                            ForEach(model.dailyAnalytics.focusSessions.prefix(4)) { focus in
                                HStack {
                                    Text(focus.startedAt.formatted(date: .omitted, time: .shortened))
                                    Text("–")
                                    Text(focus.endedAt.formatted(date: .omitted, time: .shortened))
                                    Spacer()
                                    Text(chronosDuration(focus.productiveDuration)).monospacedDigit()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                        .padding(.vertical, 6)
                    }

                    GroupBox("Top applications") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(model.dailyAnalytics.applications.prefix(4)) { app in
                                HStack {
                                    Text(app.name).lineLimit(1)
                                    Spacer()
                                    Text(chronosDuration(app.duration)).monospacedDigit().foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(28)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value).font(.title2.weight(.semibold)).monospacedDigit()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
    }
}

enum ChronosColor {
    static func color(for classification: CategoryClassification) -> Color {
        switch classification {
        case .productive: return .blue
        case .neutral: return .gray
        case .distraction: return .orange
        case .other: return .secondary
        }
    }
}
