import SwiftUI
import SwiftData

// MARK: - Style Definitions
struct UIStyle {
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let listIconSize: CGFloat = 16
    static let sectionPaddingH: CGFloat = 12
    static let sectionPaddingV: CGFloat = 12
    static let sectionHeaderFont: Font = .system(size: 12, weight: .semibold)
    static let groupHeaderFont: Font = .subheadline
    static let captionFont: Font = .caption
    static let dividerColor: Color = Color(NSColor(hex: "#2a2a2a"))
    static let backgroundSidebar: Color = Color(NSColor(hex: "#252525"))
    static let backgroundInspector: Color = Color(NSColor(hex: "#252525"))
}

// MARK: - SidebarFiltersView
struct SidebarFiltersView: View {
    @Binding var filterFlag: Flag?
    @Binding var filterRating: Int
    @Binding var filterColorLabel: ColorLabel?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 旗标
            HStack(spacing: 16) {
                ForEach([Flag.pick, Flag.reject, Flag.none], id: \.self) { flag in
                    FlagIcon(flag: flag, current: filterFlag) { toggleFlag(flag) }
                }
            }

            // 评分
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= filterRating ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundColor(star <= filterRating ? .yellow : .secondary.opacity(0.4))
                        .onTapGesture {
                            if filterRating == star {
                                filterRating = 0
                            } else {
                                filterRating = star
                            }
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
            }

            // 颜色
            HStack(spacing: 8) {
                ForEach(ColorLabel.allCases.filter { $0 != .none }, id: \.rawValue) { label in
                    Circle()
                        .fill(Color(label.color))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: filterColorLabel == label ? 2 : 0)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            if filterColorLabel == label {
                                filterColorLabel = nil
                            } else {
                                filterColorLabel = label
                            }
                        }
                        .scaleEffect(filterColorLabel == label ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: filterColorLabel)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    private func toggleFlag(_ flag: Flag) {
        if filterFlag == flag {
            filterFlag = nil
        } else {
            filterFlag = flag
        }
    }
}

private struct FlagIcon: View {
    let flag: Flag
    let current: Flag?
    let action: () -> Void

    var iconName: String {
        switch flag {
        case .pick: return "checkmark.circle.fill"
        case .reject: return "xmark.circle.fill"
        case .none: return "circle"
        }
    }

    var activeColor: Color {
        switch flag {
        case .pick: return .green
        case .reject: return .red
        case .none: return .secondary
        }
    }
    
    var isSelected: Bool {
        current == flag
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.5))
                .padding(6)
                .background(isSelected ? activeColor.opacity(0.1) : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? activeColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(flagName)
    }
    
    var flagName: String {
        switch flag {
        case .pick: return "已选"
        case .reject: return "已拒"
        case .none: return "未标记"
        }
    }
}

// MARK: - SidebarView
struct SidebarView: View {
    let albums: [Album]
    let folderNodes: [FolderNode]
    @Binding var showImportSheet: Bool
    @Binding var baseScope: ContentView.BaseScope
    @Binding var filterFlag: Flag?
    @Binding var filterRating: Int
    @Binding var filterColorLabel: ColorLabel?
    @Binding var includeSubfolders: Bool
    @Binding var showAlbumManager: Bool
    @Binding var showLeftNav: Bool

    var onRevealInFinder: (FolderNode) -> Void
    var onDeleteRecursively: (FolderNode) -> Void
    var onDeleteFromDisk: (FolderNode) -> Void
    var onSyncFolder: (FolderNode) -> Void
    var onClearFilters: () -> Void

    @AppStorage("expandFolders") private var expandFolders: Bool = true
    @AppStorage("expandAlbums") private var expandAlbums: Bool = false
    @AppStorage("expandFilters") private var expandFilters: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                Section("图库") {
                    listRow(icon: "photo.on.rectangle.angled", title: "全部照片", isSelected: baseScope == .all && filterFlag == nil) {
                        baseScope = .all
                        filterFlag = nil
                    }
                }

                Section {
                    OutlineGroup(folderNodes, children: \.children) { node in
                        Button {
                            baseScope = .folder(path: node.fullPath)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.secondary)
                                Text(node.name)
                                    .lineLimit(1)
                                    .font(.system(size: 13))
                                Spacer()
                                Text("\(includeSubfolders ? node.count : node.photos.count)")
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .font(.system(size: 11))
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(action: { baseScope = .folder(path: node.fullPath) }) {
                                Label("查看照片", systemImage: "photo")
                            }
                            Button(action: { showImportSheet = true }) {
                                Label("导入…", systemImage: "square.and.arrow.down")
                            }
                            Button(action: { onSyncFolder(node) }) {
                                Label("同步", systemImage: "arrow.triangle.2.circlepath")
                            }
                            Button(action: { onRevealInFinder(node) }) {
                                Label("在 Finder 中显示", systemImage: "folder")
                            }
                            Divider()
                            Button(role: .destructive, action: { onDeleteRecursively(node) }) {
                                Label("从库移除", systemImage: "trash")
                            }
                            Button(role: .destructive, action: { onDeleteFromDisk(node) }) {
                                Label("从磁盘删除", systemImage: "trash.fill")
                            }
                        }
                        .listRowBackground((baseScope == .folder(path: node.fullPath)) ? Color.accentColor.opacity(0.18) : Color.clear)
                    }
                } header: {
                    HStack {
                        Text("文件夹")
                            .font(UIStyle.sectionHeaderFont)
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("子文件夹", isOn: $includeSubfolders)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .scaleEffect(0.7)
                    }
                }

                Section {
                    ForEach(albums) { album in
                        listRow(
                            icon: album.isSmartAlbum ? "gearshape" : "rectangle.stack",
                            title: album.name,
                            isSelected: baseScope == .album(id: album.id)
                        ) {
                            baseScope = .album(id: album.id)
                        }
                    }

                    Button(action: { showAlbumManager = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .frame(width: 16)
                            Text("新建/管理相册…")
                                .font(.system(size: 12))
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.leading, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("相册")
                        .font(UIStyle.sectionHeaderFont)
                        .foregroundColor(.secondary)
                }

                Section {
                    SidebarFiltersView(
                        filterFlag: $filterFlag,
                        filterRating: $filterRating,
                        filterColorLabel: $filterColorLabel
                    )
                    .listRowBackground(Color.clear)
                    .padding(.leading, 4)
                } header: {
                    HStack {
                        Text("筛选")
                            .font(UIStyle.sectionHeaderFont)
                            .foregroundColor(.secondary)
                        Spacer()
                        if filterFlag != nil || filterRating > 0 || filterColorLabel != nil {
                            Button(action: onClearFilters) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .help("清除所有筛选")
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(UIStyle.backgroundSidebar)
    }

    private var header: some View {
        VStack(spacing: 0) {
            // Import Button as a prominent action
            Button(action: { showImportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入照片")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(12)
            
            Divider()
                .padding(.bottom, 0)
        }
    }

    private func listRow(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 16)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
