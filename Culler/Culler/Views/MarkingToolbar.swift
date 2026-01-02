import SwiftUI
import SwiftData

struct MarkingToolbar: View {
    let selectedPhotos: Set<UUID>
    let photos: [Photo]
    let modelContext: ModelContext

    var selectedPhotoObjects: [Photo] {
        photos.filter { selectedPhotos.contains($0.id) }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) {
                flagSection
                Divider().frame(height: 24)
                ratingSection
                Divider().frame(height: 24)
                colorSection

                Spacer(minLength: 12)
                selectedCount
            }

            VStack(spacing: 10) {
                HStack(spacing: 24) {
                    flagSection
                    Divider().frame(height: 24)
                    ratingSection
                    Spacer(minLength: 12)
                    selectedCount
                }
                HStack {
                    colorSection
                    Spacer(minLength: 0)
                }
            }

            VStack(spacing: 10) {
                HStack {
                    flagSection
                    Spacer(minLength: 0)
                }
                HStack {
                    ratingSection
                    Spacer(minLength: 0)
                }
                HStack {
                    colorSection
                    Spacer(minLength: 0)
                }
                HStack {
                    Spacer(minLength: 0)
                    selectedCount
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor(hex: "#1f1f1f")))
    }

    private var selectedCount: some View {
        Text("\(selectedPhotos.count) selected")
            .foregroundColor(.secondary)
            .font(.system(size: 12))
            .fixedSize(horizontal: true, vertical: false)
    }

    private var flagSection: some View {
        HStack(spacing: 12) {
            Text("Flag:")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            FlagButton(flag: .pick, icon: "checkmark.circle.fill", color: .green, shortcut: "P") {
                setFlag(.pick)
            }

            FlagButton(flag: .reject, icon: "xmark.circle.fill", color: .red, shortcut: "X") {
                setFlag(.reject)
            }

            FlagButton(flag: .none, icon: "circle", color: .gray, shortcut: "U") {
                setFlag(.none)
            }
        }
    }

    private var ratingSection: some View {
        HStack(spacing: 8) {
            Text("Rating:")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            ForEach(1...5, id: \.self) { rating in
                RatingButton(rating: rating) {
                    setRating(rating)
                }
            }

            Button(action: { setRating(0) }) {
                Text("Clear")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var colorSection: some View {
        HStack(spacing: 8) {
            Text("Color:")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                if label != .none {
                    ColorLabelButton(colorLabel: label) {
                        setColorLabel(label)
                    }
                }
            }
        }
    }

    private func setFlag(_ flag: Flag) {
        for photo in selectedPhotoObjects {
            photo.flag = flag
        }
    }

    private func setRating(_ rating: Int) {
        for photo in selectedPhotoObjects {
            photo.rating = rating
        }
    }

    private func setColorLabel(_ label: ColorLabel) {
        for photo in selectedPhotoObjects {
            photo.colorLabel = label
        }
    }
}

struct FlagButton: View {
    let flag: Flag
    let icon: String
    let color: Color
    let shortcut: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(shortcut)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)
            .background(Color(NSColor(hex: "#2a2a2a")))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct RatingButton: View {
    let rating: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 1) {
                    ForEach(1...rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }
                }
                Text("\(rating)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 36, height: 36)
            .background(Color(NSColor(hex: "#2a2a2a")))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct ColorLabelButton: View {
    let colorLabel: ColorLabel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(colorLabel.color))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
    }
}
