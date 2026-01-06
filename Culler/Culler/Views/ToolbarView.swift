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
    let showRotateButtons: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Button {
                    showLeftNav.toggle()
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
                .accessibilityIdentifier("toolbar_photo_count")

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
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text(sortOption.shortTitle)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.18))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(minWidth: 180)
                    .layoutPriority(1)
                }
                .menuStyle(.borderlessButton)

                HStack(spacing: 6) {
                    Button {
                        NotificationCenter.default.post(name: .zoomOut, object: nil)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        NotificationCenter.default.post(name: .zoomIn, object: nil)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if showRotateButtons {
                    HStack(spacing: 6) {
                        Button {
                            NotificationCenter.default.post(name: .rotateLeft, object: nil)
                        } label: {
                            Image(systemName: "rotate.left")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            NotificationCenter.default.post(name: .rotateRight, object: nil)
                        } label: {
                            Image(systemName: "rotate.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    showRightPanel.toggle()
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
        .background(WindowAccessor { window in
             // Store window reference if needed, or just use it in the gesture
        })
        .onTapGesture(count: 2) {
            if let window = NSApp.keyWindow {
                let screen = window.screen ?? NSScreen.main
                if let visible = screen?.visibleFrame {
                    window.setFrame(visible, display: true, animate: true)
                }
            }
        }
    }
}
