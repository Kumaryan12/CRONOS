import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
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
}
