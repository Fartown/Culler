import SwiftUI

struct FoldersTreeView: View {
    let nodes: [FolderNode]
    var onSelect: (FolderNode) -> Void
    var onRevealInFinder: ((FolderNode) -> Void)?
    var onDeleteRecursively: ((FolderNode) -> Void)?

    var body: some View {
        List {
            OutlineGroup(nodes, children: \.children) { node in
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(node.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(node.fullPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text("\(node.count) photos")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { onSelect(node) }
                .contextMenu {
                    Button(action: { onSelect(node) }) { Label("View Photos", systemImage: "photo") }
                    if let reveal = onRevealInFinder { Button(action: { reveal(node) }) { Label("Show in Finder", systemImage: "folder") } }
                    if let remove = onDeleteRecursively { Button(role: .destructive, action: { remove(node) }) { Label("Remove from Library", systemImage: "trash") } }
                }
                .accessibilityIdentifier("folder_node_\(node.fullPath)")
            }
        }
        .listStyle(.inset)
        .accessibilityIdentifier("folder_tree")
    }
}
