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

                DisclosureGroup(isExpanded: $expandMarking) {
                    VStack(alignment: .leading, spacing: UIStyle.groupSpacing) {
                        if photo.flag != .none {
                            KVRow(label: "旗标") {
                                Image(systemName: flagIconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(flagIconColor)
                            }
                        }
                        if displayedRating > 0 {
                            KVRow(label: "评分") {
                                HStack(spacing: 2) {
                                    ForEach(0..<displayedRating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                        if photo.colorLabel != .none {
                            KVRow(label: "颜色标签") {
                                Circle()
                                    .fill(Color(photo.colorLabel.color))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        if let tags = photo.tags, !tags.isEmpty {
                            KVRow(label: "标签") {
                                Text(tags.map { $0.name }.joined(separator: ", "))
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        if photo.flag == .none && displayedRating == 0 && photo.colorLabel == .none && (photo.tags?.isEmpty ?? true) {
                            Text("暂无标记")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    } label: {
                        Text("标记")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                if hasCameraInfo {
                    DisclosureGroup(isExpanded: $expandCamera) {
                        if let make = photo.cameraMake { InfoRow(label: "厂商", value: make) }
                        if let model = photo.cameraModel { InfoRow(label: "机身", value: model) }
                        if let lens = photo.lens { InfoRow(label: "镜头", value: lens) }
                    } label: {
                        Text("相机")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if hasExposureInfo {
                    DisclosureGroup(isExpanded: $expandExposure) {
                        if let focalLength = photo.focalLength, focalLength.isFinite { InfoRow(label: "焦距", value: "\(Int(focalLength))mm") }
                        if let aperture = photo.aperture { InfoRow(label: "光圈", value: "f/\(String(format: "%.1f", aperture))") }
                        if let shutter = photo.shutterSpeed { InfoRow(label: "快门", value: shutter) }
                        if let iso = photo.iso { InfoRow(label: "ISO", value: "\(iso)") }
                    } label: {
                        Text("曝光")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                DisclosureGroup(isExpanded: $expandFile) {
                    if let width = photo.width, let height = photo.height {
                        InfoRow(label: "尺寸", value: "\(width) × \(height)")
                    }
                    InfoRow(label: "大小", value: ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file))
                    KVRow(label: "路径") {
                        HStack(spacing: UIStyle.kvSpacing) {
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

    private var tagsTextOptional: String? {
        if let tags = photo.tags, !tags.isEmpty {
            return tags.map { $0.name }.joined(separator: ", ")
        }
        return nil
    }

    private var flagValue: String? {
        photo.flag == .none ? nil : flagText
    }

    private var ratingValue: String? {
        displayedRating > 0 ? "\(displayedRating)" : nil
    }

    private var colorLabelValue: String? {
        photo.colorLabel == .none ? nil : photo.colorLabel.name
    }

    private var hasMarkingInfo: Bool {
        flagValue != nil || ratingValue != nil || colorLabelValue != nil || tagsTextOptional != nil
    }

    private var hasCameraInfo: Bool {
        photo.cameraMake != nil || photo.cameraModel != nil || photo.lens != nil
    }

    private var hasExposureInfo: Bool {
        photo.focalLength != nil || photo.aperture != nil || photo.shutterSpeed != nil || photo.iso != nil
    }
}

struct InfoRow: View {
    let label: String
    let value: String?

    private var trimmed: String? {
        guard let s = value?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    var body: some View {
        Group {
            if let v = trimmed {
                HStack(spacing: UIStyle.kvSpacing) {
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(width: UIStyle.kvLabelWidth, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(v)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct KVRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: UIStyle.kvSpacing) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: UIStyle.kvLabelWidth, alignment: .leading)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
