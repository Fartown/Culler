import SwiftUI
import AppKit

struct InfoPanelView: View {
    let photo: Photo
    @State private var expandCamera: Bool = true
    @State private var expandExposure: Bool = true
    @State private var expandFile: Bool = true
    @State private var expandMarking: Bool = true

    var body: some View {
        InfoPanelContent(
            photo: photo,
            expandCamera: $expandCamera,
            expandExposure: $expandExposure,
            expandFile: $expandFile,
            expandMarking: $expandMarking
        )
    }
}

struct InfoPanelContent: View {
    let photo: Photo
    @Binding var expandCamera: Bool
    @Binding var expandExposure: Bool
    @Binding var expandFile: Bool
    @Binding var expandMarking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                GeometryReader { proxy in
                    let w = proxy.size.width
                    ZStack {
                        AsyncThumbnailView(photo: photo, size: max(w, 200), contentMode: .fit)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(4)

                        if photo.isVideo {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                                .accessibilityLabel("视频")
                        }
                    }
                }
                .frame(height: 200)

                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([photo.fileURL])
                    }) {
                        Text(photo.fileName)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if let dateTaken = photo.dateTaken {
                        InfoRow(label: "拍摄时间", value: dateTaken.formatted())
                    }

                    InfoRow(label: "导入时间", value: photo.dateImported.formatted())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                DisclosureGroup(isExpanded: $expandMarking) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("旗标")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                Image(systemName: flagIconName)
                                    .font(.system(size: 14))
                                    .foregroundColor(flagIconColor)
                                Text(flagText)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("评分")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= displayedRating ? "star.fill" : "star")
                                        .font(.system(size: 11))
                                        .foregroundColor(i <= displayedRating ? .yellow : .secondary)
                                }
                                Text("(\(photo.rating))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("颜色标签")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                if photo.colorLabel == .none {
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Circle()
                                        .fill(Color(photo.colorLabel.color))
                                        .frame(width: 12, height: 12)
                                }
                                Text(photo.colorLabel.name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    InfoRow(label: "标签", value: tagsText)
                }
            } label: {
                Text("标记")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

                Divider()

                DisclosureGroup(isExpanded: $expandCamera) {
                    if let make = photo.cameraMake {
                        InfoRow(label: "厂商", value: make)
                    }
                    if let model = photo.cameraModel {
                        InfoRow(label: "机身", value: model)
                    }
                    if let lens = photo.lens {
                        InfoRow(label: "镜头", value: lens)
                    }
                } label: {
                    Text("相机")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandExposure) {
                    if let focalLength = photo.focalLength {
                        InfoRow(label: "焦距", value: "\(Int(focalLength))mm")
                    }
                    if let aperture = photo.aperture {
                        InfoRow(label: "光圈", value: "f/\(String(format: "%.1f", aperture))")
                    }
                    if let shutter = photo.shutterSpeed {
                        InfoRow(label: "快门", value: shutter)
                    }
                    if let iso = photo.iso {
                        InfoRow(label: "ISO", value: "\(iso)")
                    }
                } label: {
                    Text("曝光")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandFile) {
                    if let width = photo.width, let height = photo.height {
                        InfoRow(label: "尺寸", value: "\(width) × \(height)")
                    }
                    InfoRow(label: "大小", value: ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("路径")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Text(photo.filePath)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([photo.fileURL])
                            }) {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.plain)
                        }
                    }
            } label: {
                Text("文件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var displayedRating: Int {
        max(0, min(photo.rating, 5))
    }

    private var flagIconName: String {
        switch photo.flag {
        case .pick:
            return "checkmark.circle.fill"
        case .reject:
            return "xmark.circle.fill"
        case .none:
            return "circle"
        }
    }

    private var flagIconColor: Color {
        switch photo.flag {
        case .pick:
            return .green
        case .reject:
            return .red
        case .none:
            return .secondary
        }
    }

    private var flagText: String {
        switch photo.flag {
        case .pick: return "已选"
        case .reject: return "已拒"
        case .none: return "未标记"
        }
    }

    private var tagsText: String {
        if let tags = photo.tags, !tags.isEmpty {
            return tags.map { $0.name }.joined(separator: ", ")
        }
        return "无"
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
