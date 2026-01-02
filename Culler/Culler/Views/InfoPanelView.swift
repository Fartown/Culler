import SwiftUI

struct InfoPanelView: View {
    let photo: Photo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncThumbnailView(photo: photo, size: 280)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 8) {
                    Text(photo.fileName)
                        .font(.headline)
                        .lineLimit(2)

                    if let dateTaken = photo.dateTaken {
                        InfoRow(label: "Date Taken", value: dateTaken.formatted())
                    }

                    InfoRow(label: "Date Imported", value: photo.dateImported.formatted())
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Camera")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let make = photo.cameraMake {
                        InfoRow(label: "Make", value: make)
                    }
                    if let model = photo.cameraModel {
                        InfoRow(label: "Model", value: model)
                    }
                    if let lens = photo.lens {
                        InfoRow(label: "Lens", value: lens)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Exposure")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

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
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("File")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let width = photo.width, let height = photo.height {
                        InfoRow(label: "Dimensions", value: "\(width) × \(height)")
                    }
                    InfoRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: photo.fileSize, countStyle: .file))
                    InfoRow(label: "Path", value: photo.filePath)
                }

                Spacer()
            }
            .padding(16)
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
            Text(value)
                .font(.system(size: 12))
                .lineLimit(3)
        }
    }
}
