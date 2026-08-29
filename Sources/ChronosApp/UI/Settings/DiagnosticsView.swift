import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "Diagnostics", subtitle: "Energy and collector health.")
            EmptyStateView(title: "Diagnostics will appear here", icon: "gauge.with.dots.needle.50percent")
        }
        .padding(28)
    }
}
