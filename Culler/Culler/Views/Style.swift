import SwiftUI

struct UIStyle {
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let listIconSize: CGFloat = 16
    static let sectionPaddingH: CGFloat = 12
    static let sectionPaddingV: CGFloat = 12
    static let sectionHeaderFont: Font = .system(size: 12, weight: .semibold)
    static let groupHeaderFont: Font = .subheadline
    static let captionFont: Font = .caption
    static let dividerColor: Color = Color(NSColor(hex: "#2a2a2a"))
    static let backgroundSidebar: Color = Color(NSColor(hex: "#252525"))
    static let backgroundInspector: Color = Color(NSColor(hex: "#252525"))
}

struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(UIStyle.dividerColor)
            .frame(height: 1)
    }
}

