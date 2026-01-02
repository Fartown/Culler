import Foundation

struct FolderNode: Identifiable, Hashable {
    let id: String
    let name: String
    let fullPath: String
    var children: [FolderNode]?
    let count: Int
    let photos: [Photo]

    static func buildTree(from photos: [Photo]) -> [FolderNode] {
        let folderMap: [String: [Photo]] = Dictionary(grouping: photos) { photo in
            URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().standardizedFileURL.path
        }

        var nodeByPath: [String: FolderNode] = [:]
        for (path, ps) in folderMap {
            let name = URL(fileURLWithPath: path).lastPathComponent
            nodeByPath[path] = FolderNode(id: path, name: name, fullPath: path, children: nil, count: ps.count, photos: ps)
        }

        var childrenMap: [String: [String]] = [:]
        for path in nodeByPath.keys {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL.path
            if parent != path, nodeByPath[parent] != nil {
                childrenMap[parent, default: []].append(path)
            }
        }

        let roots: [String] = nodeByPath.keys.filter { path in
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL.path
            return nodeByPath[parent] == nil
        }

        func buildNode(_ path: String) -> FolderNode {
            let base = nodeByPath[path]!
            let kids = (childrenMap[path] ?? []).sorted { URL(fileURLWithPath: $0).lastPathComponent.lowercased() < URL(fileURLWithPath: $1).lastPathComponent.lowercased() }
            var builtChildren: [FolderNode] = []
            for childPath in kids {
                builtChildren.append(buildNode(childPath))
            }
            return FolderNode(id: base.id, name: base.name, fullPath: base.fullPath, children: builtChildren.isEmpty ? nil : builtChildren, count: base.count, photos: base.photos)
        }

        return roots.map { buildNode($0) }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
