import ChronosCore
import SwiftUI

struct TimelineView: View {
    @ObservedObject var model: AppModel
    @State private var selectedSession: ActivitySession?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "Timeline", subtitle: "Every completed activity boundary today.")

            if model.todaySessions.isEmpty {
                EmptyStateView(title: "No timeline yet", icon: "timeline.selection")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(model.todaySessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                TimelineSessionRow(session: session, category: category(for: session))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(28)
        .sheet(item: $selectedSession) { session in
            VStack(alignment: .leading, spacing: 14) {
                Text(session.applicationName).font(.title2.weight(.semibold))
                LabeledContent("Started", value: session.startedAt.formatted())
                LabeledContent("Ended", value: session.endedAt.formatted())
                LabeledContent("Duration", value: chronosDuration(session.duration))
                LabeledContent("Bundle ID", value: session.applicationBundleID)
                if session.isUncertain {
                    Label("Recovered conservatively after an interruption", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .padding(24)
            .frame(width: 440)
        }
    }

    private func category(for session: ActivitySession) -> ActivityCategory {
        if let stored = ActivityCategory.category(id: session.categoryID) { return stored }
        return ApplicationCategorizer().category(
            bundleID: session.applicationBundleID,
            applicationName: session.applicationName
        )
    }
}

private struct TimelineSessionRow: View {
    let session: ActivitySession
    let category: ActivityCategory
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                Text(session.endedAt.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .font(.caption.monospacedDigit())
            .frame(width: 72)

            RoundedRectangle(cornerRadius: 3)
                .fill(ChronosColor.color(for: category.classification))
                .frame(width: 6, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.applicationName).fontWeight(.medium)
                Text(category.name).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(chronosDuration(session.duration)).monospacedDigit().foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(hovering ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
        .onHover { hovering = $0 }
    }
}
