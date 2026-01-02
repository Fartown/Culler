import SwiftUI

struct FoldersTreeView: View {
    let nodes: [FolderNode]
    var onSelect: (FolderNode) -> Void
    var onRevealInFinder: ((FolderNode) -> Void)?
    var onDeleteRecursively: ((FolderNode) -> Void)?
    var onDeleteFromDisk: ((FolderNode) -> Void)?
    var onImport: (() -> Void)?

    @State private var hoverPath: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            List {
                OutlineGroup(nodes, children: \.children) { node in
                    HStack(spacing: 10) {
                        ZStack {
                            LinearGradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(width: 28, height: 28)
                                .cornerRadius(6)
                            Image(systemName: node.isFile ? "photo" : "folder.fill")
                                .foregroundColor(node.isFile ? .secondary : .blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(node.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                if !node.isFile {
                                    Text("\(node.count)")
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(10)
                                }
                            }
                            Text(node.fullPath)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.disabled)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((hoverPath == node.fullPath) ? Color.white.opacity(0.05) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { if !node.isFile { onSelect(node) } }
                    .onHover { hovering in hoverPath = hovering ? node.fullPath : nil }
                    .contextMenu {
                        if !node.isFile {
                            Button(action: { onSelect(node) }) { Label("View Photos", systemImage: "photo") }
                            if let onImport { Button(action: { onImport() }) { Label("Import...", systemImage: "square.and.arrow.down") } }
                            if let reveal = onRevealInFinder { Button(action: { reveal(node) }) { Label("Show in Finder", systemImage: "folder") } }
                            if let remove = onDeleteRecursively { Button(role: .destructive, action: { remove(node) }) { Label("Remove from Library", systemImage: "trash") } }
                            if let removeDisk = onDeleteFromDisk { Button(role: .destructive, action: { removeDisk(node) }) { Label("Delete from Disk", systemImage: "trash.fill") } }
                        } else {
                            Button(action: {
                                NSWorkspace.shared.selectFile(node.fullPath, inFileViewerRootedAtPath: URL(fileURLWithPath: node.fullPath).deletingLastPathComponent().path)
                            }) { Label("Show in Finder", systemImage: "doc") }
                        }
                    }
                    .accessibilityIdentifier("folder_node_\(node.fullPath)")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .accessibilityIdentifier("folder_tree")
    }
}
