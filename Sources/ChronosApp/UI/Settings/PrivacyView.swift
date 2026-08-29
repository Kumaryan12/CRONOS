import ChronosCore
import SwiftUI

struct PrivacyView: View {
    @ObservedObject var model: AppModel
    @State private var rangeStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var pendingDeletion: PendingDeletion?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Privacy", subtitle: "Everything stays local and under your control.")

                HStack {
                    Label(
                        model.snapshot.isTracking ? "Tracking active" : "Privacy mode — tracking paused",
                        systemImage: model.snapshot.isTracking ? "checkmark.circle.fill" : "hand.raised.fill"
                    )
                    .foregroundStyle(model.snapshot.isTracking ? .green : .orange)
                    Spacer()
                    Button(model.snapshot.isTracking ? "Enter Privacy Mode" : "Resume Tracking") {
                        model.toggleTracking()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

                GroupBox("Application rules") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Excluded applications close the active session immediately and their identity is not written to the database. Common password managers are excluded automatically.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if model.applicationRules.isEmpty {
                            Text("Applications appear here after Chronos observes them.")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 10)
                        } else {
                            ForEach(model.applicationRules) { rule in
                                ApplicationRuleRow(rule: rule, onChange: model.saveApplicationRule)
                                if rule.id != model.applicationRules.last?.id { Divider() }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Your data") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Button("Export All Data…") { model.exportAllData() }
                            Spacer()
                            Button("Delete Today", role: .destructive) { pendingDeletion = .today }
                            Button("Delete All Data", role: .destructive) { pendingDeletion = .all }
                        }

                        Divider()
                        Text("Delete date range").font(.headline)
                        HStack {
                            DatePicker("From", selection: $rangeStart, displayedComponents: .date)
                            DatePicker("Through", selection: $rangeEnd, displayedComponents: .date)
                            Spacer()
                            Button("Delete Range", role: .destructive) { pendingDeletion = .range }
                        }
                    }
                    .padding(.vertical, 6)
                }

                if let message = model.privacyMessage {
                    Label(message, systemImage: "checkmark.circle").foregroundStyle(.secondary)
                }

                GroupBox("Chronos never collects") {
                    Text("Keystrokes · passwords · clipboard contents · screenshots · screen recordings · form contents · message bodies")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            }
            .padding(28)
        }
        .alert(item: $pendingDeletion) { deletion in
            Alert(
                title: Text(deletion.title),
                message: Text("This cannot be undone. Tracking will remain paused after deletion."),
                primaryButton: .destructive(Text("Delete")) { perform(deletion) },
                secondaryButton: .cancel()
            )
        }
    }

    private func perform(_ deletion: PendingDeletion) {
        switch deletion {
        case .today:
            model.deleteToday()
        case .all:
            model.deleteAllData()
        case .range:
            let calendar = Calendar.current
            guard let start = calendar.dateInterval(of: .day, for: rangeStart)?.start,
                  let endDay = calendar.dateInterval(of: .day, for: rangeEnd),
                  endDay.end > start else { return }
            model.deleteData(from: start, to: endDay.end)
        }
    }
}

private struct ApplicationRuleRow: View {
    let rule: ApplicationRule
    let onChange: (ApplicationRule) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.displayName).fontWeight(.medium)
                Text(rule.bundleID).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Picker("Category", selection: Binding(
                get: { rule.categoryID },
                set: { categoryID in
                    var updated = rule
                    updated.categoryID = categoryID
                    onChange(updated)
                }
            )) {
                Text("Automatic").tag(nil as String?)
                ForEach(ActivityCategory.defaults) { category in
                    Text(category.name).tag(category.id as String?)
                }
            }
            .labelsHidden()
            .frame(width: 150)

            Toggle("Exclude", isOn: Binding(
                get: { rule.isExcluded },
                set: { excluded in
                    var updated = rule
                    updated.isExcluded = excluded
                    onChange(updated)
                }
            ))
            .toggleStyle(.switch)
            .frame(width: 90)
        }
    }
}

private enum PendingDeletion: String, Identifiable {
    case today
    case range
    case all

    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: return "Delete today's activity?"
        case .range: return "Delete activity in this date range?"
        case .all: return "Delete all Chronos data?"
        }
    }
}
