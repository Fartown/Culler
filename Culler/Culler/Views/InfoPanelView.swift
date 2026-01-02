import SwiftUI

struct InfoPanelView: View {
    let photo: Photo
    @State private var expandCamera: Bool = true
    @State private var expandExposure: Bool = true
    @State private var expandFile: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GeometryReader { proxy in
                    let w = proxy.size.width
                    AsyncThumbnailView(photo: photo, size: max(w, 200), contentMode: .fit)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(4)
                }
                .frame(height: 200)

                VStack(alignment: .leading, spacing: 8) {
                    Text(photo.fileName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let dateTaken = photo.dateTaken {
                        InfoRow(label: "Date Taken", value: dateTaken.formatted())
                    }

                    InfoRow(label: "Date Imported", value: photo.dateImported.formatted())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor(hex: "#252525")))
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
