import SwiftUI

struct ToolbarView: View {
    @Binding var viewMode: ContentView.ViewMode
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

            HStack(spacing: 4) {
                ToolbarButton(icon: "square.grid.3x3", identifier: "toolbar_grid", isSelected: viewMode == .grid) {
                    viewMode = .grid
                }
                ToolbarButton(icon: "photo", identifier: "toolbar_single", isSelected: viewMode == .single) {
                    viewMode = .single
                }
                ToolbarButton(icon: "arrow.up.left.and.arrow.down.right", identifier: "toolbar_fullscreen", isSelected: viewMode == .fullscreen) {
                    viewMode = .fullscreen
                }
            }
            .padding(4)
            .background(Color(NSColor(hex: "#2a2a2a")))
            .cornerRadius(6)

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

struct ToolbarButton: View {
    let icon: String
    let identifier: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
