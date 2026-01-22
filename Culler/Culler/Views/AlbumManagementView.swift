import SwiftUI
import SwiftData

struct AlbumManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var albums: [Album]
    @Query private var tags: [Tag]

    @State private var selectedAlbum: Album?
    @State private var showNewAlbumSheet = false
    @State private var showNewTagSheet = false
    @State private var newAlbumName = ""
    @State private var newTagName = ""
    @State private var newTagColor = "#007AFF"

    private var rootAlbums: [Album] {
        albums.filter { $0.parent == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("管理相册与标签")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("关闭")
            }
            .padding()

            Divider()

                HSplitView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("相册")
                                .font(.headline)
                            Spacer()
                            Button(action: { showNewAlbumSheet = true }) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("album_manager_new_album_button")
                            .help("新建相册")
                            if UITestConfig.isEnabled {
                                Button("删除最近创建") {
                                    deleteLastAlbumIfAny()
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("album_manager_delete_last_album")
                            }
                        }
                        .padding()

                    List(selection: $selectedAlbum) {
                        ForEach(rootAlbums) { album in
                            AlbumRow(album: album, level: 0)
                        }
                        .onDelete(perform: deleteAlbums)
                    }

                    Divider()

                        HStack {
                            Text("标签")
                                .font(.headline)
                            Spacer()
                            Button(action: { showNewTagSheet = true }) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("album_manager_new_tag_button")
                            .help("新建标签")
                            if UITestConfig.isEnabled {
                                Button("删除最近创建") {
                                    deleteLastTagIfAny()
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("album_manager_delete_last_tag")
                            }
                        }
                        .padding()

                    ScrollView {
                        FlowLayout(spacing: 8) {
                            ForEach(tags) { tag in
                                TagChip(tag: tag) {
                                    deleteTag(tag)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 320)
                .background(Color(NSColor(hex: "#252525")))

                if let album = selectedAlbum {
                    AlbumDetailView(album: album)
                } else {
                    Text("请选择一个相册")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showNewAlbumSheet) {
            VStack(spacing: 16) {
                Text("新建相册")
                    .font(.headline)
                TextField("相册名称", text: $newAlbumName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("取消") {
                        showNewAlbumSheet = false
                        newAlbumName = ""
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("创建") {
                        createAlbum()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newAlbumName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
        .sheet(isPresented: $showNewTagSheet) {
            VStack(spacing: 16) {
                Text("新建标签")
                    .font(.headline)
                TextField("标签名称", text: $newTagName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("颜色：")
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: newTagColor) ?? .blue },
                        set: { newTagColor = $0.hexString }
                    ))
                }

                HStack {
                    Button("取消") {
                        showNewTagSheet = false
                        newTagName = ""
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button("创建") {
                        createTag()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newTagName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }

    private func createAlbum() {
        let album = Album(name: newAlbumName)
        modelContext.insert(album)
        showNewAlbumSheet = false
        newAlbumName = ""
    }

    private func createTag() {
        let tag = Tag(name: newTagName, colorHex: newTagColor)
        modelContext.insert(tag)
        showNewTagSheet = false
        newTagName = ""
    }

    private func deleteAlbums(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rootAlbums[index])
        }
    }

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
    }

    private func deleteLastAlbumIfAny() {
        if let last = rootAlbums.last { modelContext.delete(last) }
    }

    private func deleteLastTagIfAny() {
        if let tag = tags.last { modelContext.delete(tag) }
    }
}

struct AlbumRow: View {
    let album: Album
    let level: Int

    var body: some View {
        HStack {
            Image(systemName: album.isSmartAlbum ? "gearshape" : "folder")
                .foregroundColor(.secondary)
            Text(album.name)
            Spacer()
            Text("\(album.photos?.count ?? 0)")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.leading, CGFloat(level * 16))
    }
}

struct AlbumDetailView: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(album.name)
                    .font(.title2)
                Spacer()
                Text("\(album.photos?.count ?? 0) 张")
                    .foregroundColor(.secondary)
            }
            .padding()

            if let photos = album.photos, !photos.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(photos) { photo in
                            AsyncThumbnailView(photo: photo, size: 100, contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("当前没有内容")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
    }
}

struct TagChip: View {
    let tag: Tag
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: tag.colorHex) ?? .blue)
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.system(size: 12))
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor(hex: "#3a3a3a")))
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    var hexString: String {
        guard let components = NSColor(self).cgColor.components else { return "#007AFF" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
