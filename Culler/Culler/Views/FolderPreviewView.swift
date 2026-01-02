import SwiftUI

struct FolderPreviewView: View {
    let photos: [Photo]
    @Binding var selectedPhotos: Set<UUID>
    @Binding var currentPhoto: Photo?
    @Binding var includeSubfolders: Bool
    let folderPath: String?
    @State private var showQuickLook: Bool = false

    var breadcrumb: String {
        guard let folderPath else { return "" }
        let url = URL(fileURLWithPath: folderPath)
        let components = url.pathComponents.suffix(3)
        return components.joined(separator: "/")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if folderPath != nil {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text(breadcrumb)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("包含子文件夹", isOn: $includeSubfolders)
                    .toggleStyle(.switch)
                if let currentPhoto {
                    let url = URL(fileURLWithPath: currentPhoto.filePath)
                    Button("预览") { NSWorkspace.shared.open(url) }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            PhotoGridView(
                photos: photos,
                selectedPhotos: $selectedPhotos,
                currentPhoto: $currentPhoto,
                scrollAnchor: nil,
                onDoubleClick: {}
            )
        }
        
    }
}
