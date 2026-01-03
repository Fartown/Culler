import SwiftUI

struct InspectorView: View {
    let photo: Photo?
    
    @State private var expandInfo: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DisclosureGroup(isExpanded: $expandInfo) {
                    if let photo {
                        InfoPanelView(photo: photo)
                    } else {
                        EmptyStateView(systemImage: "info.circle", title: "未选择照片", subtitle: "请选择一张照片以查看信息")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                } label: {
                    Text("信息")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor(hex: "#252525")))
    }
}
