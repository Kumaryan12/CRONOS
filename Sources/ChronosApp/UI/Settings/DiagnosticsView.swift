import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var model: AppModel
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Diagnostics", subtitle: "Measured collector and storage health.")

                HStack(spacing: 12) {
                    MetricCard(title: "CPU", value: String(format: "%.2f%%", model.diagnostics.collectorCPUPercent), icon: "cpu")
                    MetricCard(title: "MEMORY", value: bytes(model.diagnostics.memoryBytes), icon: "memorychip")
                    MetricCard(title: "DATABASE", value: bytes(UInt64(max(0, model.diagnostics.databaseBytes))), icon: "externaldrive")
                    MetricCard(title: "UPTIME", value: chronosDuration(model.diagnostics.collectorUptime), icon: "clock.arrow.circlepath")
                }

                GroupBox("Collector counters") {
                    Grid(alignment: .leading, horizontalSpacing: 44, verticalSpacing: 12) {
                        row("Events processed", "\(model.diagnostics.eventsProcessed)")
                        row("Completed sessions", "\(model.diagnostics.sessionsCompleted)")
                        row("Database writes", "\(model.diagnostics.databaseWrites)")
                        row("Events/hour", String(format: "%.1f", model.diagnostics.eventsPerHour))
                        row("Writes/hour", String(format: "%.1f", model.diagnostics.writesPerHour))
                        row("Analytics executions", "\(model.diagnostics.analyticsExecutions)")
                        row("Last aggregation", model.diagnostics.lastAggregation?.formatted() ?? "Not yet")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }

                GroupBox("Energy design") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Application, screen, wake, and session changes are notification-driven", systemImage: "checkmark.circle.fill")
                        Label("Idle state uses one tolerant 30-second timer", systemImage: "checkmark.circle.fill")
                        Label("No screenshots, process scanning, GPU work, network polling, or background AI", systemImage: "checkmark.circle.fill")
                        Label("Diagnostics refresh only while this page is visible", systemImage: "checkmark.circle.fill")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                Text("For release profiling, use Activity Monitor and Instruments Energy Log over a full workday.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
        }
        .onAppear { model.refreshDiagnostics() }
        .onReceive(timer) { _ in model.refreshDiagnostics() }
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
        }
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }
}
