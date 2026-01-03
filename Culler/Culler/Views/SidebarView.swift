import SwiftUI
import SwiftData

struct SidebarView: View {
    let albums: [Album]
    let folderNodes: [FolderNode]
    @Binding var showImportSheet: Bool
    @Binding var baseScope: ContentView.BaseScope
    @Binding var filterFlag: Flag?
    @Binding var includeSubfolders: Bool
    @Binding var showAlbumManager: Bool
    @Binding var showLeftNav: Bool

    var onRevealInFinder: (FolderNode) -> Void
    var onDeleteRecursively: (FolderNode) -> Void
    var onDeleteFromDisk: (FolderNode) -> Void
    var onSyncFolder: (FolderNode) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                Section("图库") {
                    listRow(icon: "photo.on.rectangle.angled", title: "全部照片", isSelected: baseScope == .all && filterFlag == nil) {
                        baseScope = .all
                        filterFlag = nil
                    }
                    listRow(icon: "checkmark.circle.fill", title: "已选", isSelected: filterFlag == .pick) {
                        baseScope = .all
                        filterFlag = (filterFlag == .pick) ? nil : .pick
                    }
                    listRow(icon: "xmark.circle.fill", title: "已拒", isSelected: filterFlag == .reject) {
                        baseScope = .all
                        filterFlag = (filterFlag == .reject) ? nil : .reject
                    }
                }

                Section("文件夹") {
                    HStack {
                        Text("包含子文件夹")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: $includeSubfolders)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .listRowBackground(Color.clear)

                    OutlineGroup(folderNodes, children: \.children) { node in
                        Button {
                            baseScope = .folder(path: node.fullPath)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(node.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(includeSubfolders ? node.count : node.photos.count)")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                            }
                            .contentShape(Rectangle())
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
                }

                Section("相册") {
                    ForEach(albums) { album in
                        listRow(
                            icon: album.isSmartAlbum ? "gearshape" : "folder",
                            title: album.name,
                            isSelected: baseScope == .album(id: album.id)
                        ) {
                            baseScope = .album(id: album.id)
                        }
                    }

                    Button(action: { showAlbumManager = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .frame(width: 16)
                            Text("管理相册与标签…")
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(NSColor(hex: "#252525")))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CULLER")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showLeftNav = false }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Button(action: { showImportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("导入")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(NSColor(hex: "#007AFF")))
                .foregroundColor(.white)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    private func listRow(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}
