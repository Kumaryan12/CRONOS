import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @AppStorage("idleThresholdMinutes") private var idleThresholdMinutes = 5.0

    var body: some View {
        Form {
            Section("Collection") {
                HStack {
                    Text("Idle threshold")
                    Slider(
                        value: Binding(
                            get: { idleThresholdMinutes },
                            set: {
                                idleThresholdMinutes = $0
                                model.updateIdleThreshold(minutes: $0)
                            }
                        ),
                        in: 1...30,
                        step: 1
                    )
                    Text("\(Int(idleThresholdMinutes)) min")
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }

                Toggle("Collect window titles", isOn: .constant(false))
                    .disabled(true)
                Text("Chronos V1 never collects window titles.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Lifecycle") {
                Toggle(
                    "Launch Chronos when I log in",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: model.setLaunchAtLogin
                    )
                )
                Text("Uses macOS Service Management. Registration requires running the packaged Chronos.app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Text("Chronos never records keystrokes, screenshots, clipboard contents, or message bodies.")
                Text("Pause from the menu bar to stop retaining all activity events immediately.")
                    .foregroundStyle(.secondary)
            }

            if let error = model.lifecycleError {
                Section("Login item error") {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .frame(width: 520, height: 430)
    }
}
