import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LabeledContent("Productive", value: chronosDuration(model.dailyAnalytics.productiveDuration))
            LabeledContent("Distraction", value: chronosDuration(model.dailyAnalytics.distractionDuration))
            LabeledContent("Focus Score", value: model.dailyAnalytics.focusScore.map { String($0.score) } ?? "—")
            LabeledContent("Current", value: model.snapshot.currentApplication ?? "None")
            if let started = model.snapshot.currentSessionStartedAt {
                LabeledContent("Session started", value: started.formatted(date: .omitted, time: .shortened))
            }

            Divider()

            Button("Open Dashboard") {
                model.openDashboard()
            }
            Button(model.snapshot.isTracking ? "Pause Tracking" : "Resume Tracking") {
                model.toggleTracking()
            }
            if model.snapshot.isTracking {
                Button("Enter Privacy Mode") { model.toggleTracking() }
            }
            if #available(macOS 14.0, *) {
                SettingsLink()
            } else {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
            Divider()
            Button("Quit Chronos") {
                model.shutdown()
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 300)
    }
}
