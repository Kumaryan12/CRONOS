import SwiftUI

struct PrivacyView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "Privacy", subtitle: "Local controls and application exclusions.")
            EmptyStateView(title: "Privacy tools are being configured", icon: "hand.raised")
        }
        .padding(28)
    }
}
