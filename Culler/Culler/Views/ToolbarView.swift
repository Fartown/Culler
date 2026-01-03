import SwiftUI

struct ToolbarView: View {
    @Binding var showLeftNav: Bool
    @Binding var showRightPanel: Bool
    let scopeTitle: String
    let photoCount: Int
    let selectedCount: Int
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    let canSyncFolder: Bool
    let onSyncFolder: () -> Void
    @Binding var sortOption: SortOption

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showLeftNav.toggle() }
                } label: {
                    Image(systemName: "sidebar.leading")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Text(scopeTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }



            Spacer()

            Text("\(photoCount) 张")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            if selectedCount > 0 {
                Text("• 已选 \(selectedCount)")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            }

            Spacer()

            HStack(spacing: 8) {
                if hasActiveFilters {
                    Button("清除筛选") { onClearFilters() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                if canSyncFolder {
                    Button {
                        onSyncFolder()
                    } label: {
                        Label("同步", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            sortOption = option
                        } label: {
                            if option == sortOption {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("排序：\(sortOption.title)")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showRightPanel.toggle() }
                } label: {
                    Image(systemName: "sidebar.trailing")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor(hex: "#1f1f1f")))
    }
}


