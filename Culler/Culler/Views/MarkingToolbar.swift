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
        HStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    flagSection
                    Divider().frame(height: 24)
                    ratingSection
                    Divider().frame(height: 24)
                    colorSection
                }
                .padding(.horizontal, 4)
            }
            selectedCount
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor(hex: "#1f1f1f")))
        .overlay(
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1), alignment: .top
        )
        .frame(minHeight: 56)
    }

    private var selectedCount: some View {
        Text("\(selectedPhotos.count >= 100 ? "99+" : String(selectedPhotos.count)) selected")
            .foregroundColor(.secondary)
            .font(.system(size: 13))
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
            .accessibilityIdentifier("mark_flag_pick")

            FlagButton(flag: .reject, icon: "xmark.circle.fill", color: .red, shortcut: "X") {
                setFlag(.reject)
            }
            .accessibilityIdentifier("mark_flag_reject")

            FlagButton(flag: .none, icon: "circle", color: .gray, shortcut: "U") {
                setFlag(.none)
            }
            .accessibilityIdentifier("mark_flag_none")
        }
    }

    private var ratingSection: some View {
        HStack(spacing: 12) {
            Text("Rating:")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            ForEach(1...5, id: \.self) { rating in
                RatingButton(rating: rating) {
                    setRating(rating)
                }
                .accessibilityIdentifier("mark_rating_\(rating)")
            }

            Button(action: { setRating(0) }) {
                Text("Clear")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PressableButtonStyle())
            .buttonStyle(PressableButtonStyle())
            .accessibilityIdentifier("mark_rating_clear")
        }
    }

    private var colorSection: some View {
        HStack(spacing: 12) {
            Text("Color:")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                if label != .none {
                    ColorLabelButton(colorLabel: label) {
                        setColorLabel(label)
                    }
                    .accessibilityIdentifier("mark_color_\(label.rawValue)")
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
            ToolbarItemView(fixedWidth: 40) {
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                    Text(shortcut)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct RatingButton: View {
    let rating: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ToolbarItemView {
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
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ColorLabelButton: View {
    let colorLabel: ColorLabel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ToolbarItemView(fixedWidth: 40) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color(colorLabel.color))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct ToolbarItemView<Content: View>: View {
    @State private var hovering = false
    let content: Content
    let fixedWidth: CGFloat?
    init(fixedWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.fixedWidth = fixedWidth
        self.content = content()
    }
    var body: some View {
        content
            .padding(.horizontal, fixedWidth == nil ? 8 : 0)
            .frame(width: fixedWidth, height: 40)
            .background(Color(NSColor(hex: "#2a2a2a")))
            .cornerRadius(4)
            .scaleEffect(hovering ? 1.06 : 1)
            .onHover { h in
                withAnimation(.easeInOut(duration: 0.15)) { hovering = h }
            }
    }
}
