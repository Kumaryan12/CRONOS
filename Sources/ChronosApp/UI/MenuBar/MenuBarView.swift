import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

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
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button(model.snapshot.isTracking ? "Pause Tracking" : "Resume Tracking") {
                model.toggleTracking()
            }
            Divider()
            Button("Quit Chronos") { NSApplication.shared.terminate(nil) }
        }
        .padding(14)
        .frame(width: 300)
    }
}
