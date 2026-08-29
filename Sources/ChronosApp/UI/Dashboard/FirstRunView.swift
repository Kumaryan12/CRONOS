import SwiftUI

struct FirstRunView: View {
    @Binding var hasCompletedOnboarding: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 44))
                .foregroundStyle(.blue)
            Text("Welcome to Chronos")
                .font(.largeTitle.weight(.semibold))
            Text("Understand where your time actually goes.")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                privacyLine("Everything stays local")
                privacyLine("No keystrokes or clipboard access")
                privacyLine("No screenshots or screen recording")
                privacyLine("Pause or delete data anytime")
                privacyLine("Window-title tracking is off by default")
            }

            Button("Start Tracking") {
                onStart()
                hasCompletedOnboarding = true
            }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding(48)
    }

    private func privacyLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.primary, .green)
    }
}
