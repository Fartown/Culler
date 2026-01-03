import Foundation

struct FolderNode: Identifiable, Hashable {
    let id: String
    let name: String
    let fullPath: String
    var children: [FolderNode]?
    let count: Int
    let photos: [Photo]
    let isFile: Bool
    let photo: Photo?

    static func buildTree(from photos: [Photo]) -> [FolderNode] {
        let folderMap: [String: [Photo]] = Dictionary(grouping: photos) { photo in
            URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().standardizedFileURL.path
        }

        var nodeByPath: [String: FolderNode] = [:]
        for (path, ps) in folderMap {
            let name = URL(fileURLWithPath: path).lastPathComponent
            nodeByPath[path] = FolderNode(id: path, name: name, fullPath: path, children: nil, count: ps.count, photos: ps, isFile: false, photo: nil)
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
            let aggregatedCount = base.count + builtChildren.reduce(0) { $0 + $1.count }
            return FolderNode(id: base.id, name: base.name, fullPath: base.fullPath, children: builtChildren.isEmpty ? nil : builtChildren, count: aggregatedCount, photos: base.photos, isFile: false, photo: nil)
        }

        return roots.map { buildNode($0) }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    static func buildTreeWithFiles(from photos: [Photo]) -> [FolderNode] {
        let folderMap: [String: [Photo]] = Dictionary(grouping: photos) { photo in
            URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().standardizedFileURL.path
        }

        var nodeByPath: [String: FolderNode] = [:]
        for (path, ps) in folderMap {
            let name = URL(fileURLWithPath: path).lastPathComponent
            nodeByPath[path] = FolderNode(id: path, name: name, fullPath: path, children: nil, count: ps.count, photos: ps, isFile: false, photo: nil)
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
            let folderChildrenPaths = (childrenMap[path] ?? []).sorted { URL(fileURLWithPath: $0).lastPathComponent.lowercased() < URL(fileURLWithPath: $1).lastPathComponent.lowercased() }
            var builtChildren: [FolderNode] = []
            for childPath in folderChildrenPaths {
                builtChildren.append(buildNode(childPath))
            }
            for p in base.photos.sorted(by: { URL(fileURLWithPath: $0.filePath).lastPathComponent.lowercased() < URL(fileURLWithPath: $1.filePath).lastPathComponent.lowercased() }) {
                let filename = URL(fileURLWithPath: p.filePath).lastPathComponent
                let fileNode = FolderNode(id: p.id.uuidString, name: filename, fullPath: p.filePath, children: nil, count: 0, photos: [], isFile: true, photo: p)
                builtChildren.append(fileNode)
            }
            let aggregatedCount = base.count + builtChildren.reduce(0) { $0 + $1.count }
            return FolderNode(id: base.id, name: base.name, fullPath: base.fullPath, children: builtChildren.isEmpty ? nil : builtChildren, count: aggregatedCount, photos: base.photos, isFile: false, photo: nil)
        }

        return roots.map { buildNode($0) }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
