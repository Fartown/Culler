import SwiftUI

struct EmptyStateView: View {
    var systemImage: String = "tray"
    var title: String = "当前没有内容"
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundColor(.secondary)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

