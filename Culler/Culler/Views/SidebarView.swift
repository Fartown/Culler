import SwiftUI
import SwiftData

struct SidebarView: View {
    let albums: [Album]
    @Binding var showImportSheet: Bool
    @Binding var filterRating: Int
    @Binding var filterFlag: Flag?
    @Binding var filterColorLabel: ColorLabel?

    @State private var showNewAlbumSheet = false
    @State private var newAlbumName = ""
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CULLER")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Button(action: { showImportSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
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

            Divider()
                .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SidebarSection(title: "Library") {
                        SidebarItem(icon: "photo.on.rectangle.angled", title: "All Photos", isSelected: filterFlag == nil) {
                            filterFlag = nil
                        }
                        SidebarItem(icon: "star.fill", title: "Picked", isSelected: filterFlag == .pick) {
                            filterFlag = filterFlag == .pick ? nil : .pick
                        }
                        SidebarItem(icon: "xmark.circle.fill", title: "Rejected", isSelected: filterFlag == .reject) {
                            filterFlag = filterFlag == .reject ? nil : .reject
                        }
                    }

                    SidebarSection(title: "Filter by Rating") {
                        ForEach(0...5, id: \.self) { rating in
                            HStack {
                                if rating == 0 {
                                    Text("All")
                                } else {
                                    HStack(spacing: 2) {
                                        ForEach(1...rating, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    Text("& up")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if filterRating == rating {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(filterRating == rating ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                filterRating = rating
                            }
                        }
                    }

                    SidebarSection(title: "Color Labels") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 24))], spacing: 8) {
                            ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                                if label != .none {
                                    Circle()
                                        .fill(Color(label.color))
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(filterColorLabel == label ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            filterColorLabel = filterColorLabel == label ? nil : label
                                        }
                                }
                            }
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                )
                                .onTapGesture {
                                    filterColorLabel = nil
                                }
                        }
                        .padding(.horizontal, 8)
                    }

                    Divider()

                    SidebarSection(title: "Albums") {
                        ForEach(albums) { album in
                            SidebarItem(
                                icon: album.isSmartAlbum ? "gearshape" : "folder",
                                title: album.name,
                                isSelected: false
                            )
                        }

                        Button(action: { showNewAlbumSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("New Album")
                            }
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(NSColor(hex: "#252525")))
        .sheet(isPresented: $showNewAlbumSheet) {
            VStack(spacing: 16) {
                Text("New Album")
                    .font(.headline)
                TextField("Album Name", text: $newAlbumName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") {
                        showNewAlbumSheet = false
                        newAlbumName = ""
                    }
                    Spacer()
                    Button("Create") {
                        let album = Album(name: newAlbumName)
                        modelContext.insert(album)
                        showNewAlbumSheet = false
                        newAlbumName = ""
                    }
                    .disabled(newAlbumName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}

struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            content
        }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
