import SwiftUI

struct ToolbarView: View {
    @Binding var viewMode: ContentView.ViewMode
    let photoCount: Int
    let selectedCount: Int

    var body: some View {
        HStack {
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

            Text("\(photoCount) photos")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            if selectedCount > 0 {
                Text("• \(selectedCount) selected")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
            }

            Spacer()

            HStack(spacing: 8) {
                Menu {
                    Button("Date Taken") {}
                    Button("Date Imported") {}
                    Button("File Name") {}
                    Button("Rating") {}
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
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
