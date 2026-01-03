import SwiftUI
import AppKit

struct InfoPanelView: View {
    let photo: Photo
    @State private var expandCamera: Bool = true
    @State private var expandExposure: Bool = true
    @State private var expandFile: Bool = true
    @State private var expandMarking: Bool = true

    var body: some View {
        ScrollView {
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
                        InfoRow(label: "Date Taken", value: dateTaken.formatted())
                    }

                    InfoRow(label: "Date Imported", value: photo.dateImported.formatted())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                DisclosureGroup(isExpanded: $expandMarking) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Flag")
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
                            Text("Rating")
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
                            Text("Color Label")
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

                        InfoRow(label: "Tags", value: tagsText)
                    }
                } label: {
                    Text("Marking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandCamera) {
                    if let make = photo.cameraMake {
                        InfoRow(label: "Make", value: make)
                    }
                    if let model = photo.cameraModel {
                        InfoRow(label: "Model", value: model)
                    }
                    if let lens = photo.lens {
                        InfoRow(label: "Lens", value: lens)
                    }
                } label: {
                    Text("Camera")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandExposure) {
                    if let focalLength = photo.focalLength {
                        InfoRow(label: "Focal Length", value: "\(Int(focalLength))mm")
                    }
                    if let aperture = photo.aperture {
                        InfoRow(label: "Aperture", value: "f/\(String(format: "%.1f", aperture))")
                    }
                    if let shutter = photo.shutterSpeed {
                        InfoRow(label: "Shutter Speed", value: shutter)
                    }
                    if let iso = photo.iso {
                        InfoRow(label: "ISO", value: "\(iso)")
                    }
                } label: {
                    Text("Exposure")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandFile) {
                    if let width = photo.width, let height = photo.height {
                        InfoRow(label: "Dimensions", value: "\(width) × \(height)")
                    }
                    InfoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file))
                    InfoRow(label: "Path", value: photo.filePath)
                } label: {
                    Text("File")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .padding(.bottom, 72)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor(hex: "#252525")))
    }
}

extension InfoPanelView {
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
        case .pick: return "Pick"
        case .reject: return "Reject"
        case .none: return "None"
        }
    }

    private var tagsText: String {
        if let tags = photo.tags, !tags.isEmpty {
            return tags.map { $0.name }.joined(separator: ", ")
        }
        return "None"
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
