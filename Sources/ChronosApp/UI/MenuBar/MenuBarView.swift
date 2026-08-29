import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LabeledContent("Current application", value: model.snapshot.currentApplication ?? "None")
            LabeledContent("Idle", value: model.snapshot.isIdle ? "Yes" : "No")
            LabeledContent("Screen", value: model.snapshot.isScreenAwake ? "Awake" : "Asleep")

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
