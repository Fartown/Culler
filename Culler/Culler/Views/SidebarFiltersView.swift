import SwiftUI

struct SidebarFiltersView: View {
    @Binding var filterFlag: Flag?
    @Binding var filterRating: Int
    @Binding var filterColorLabel: ColorLabel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 旗标
            VStack(alignment: .leading, spacing: 8) {
                Text("旗标")
                    .font(UIStyle.captionFont)
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    FlagIcon(flag: .pick, current: filterFlag) { toggleFlag(.pick) }
                    FlagIcon(flag: .reject, current: filterFlag) { toggleFlag(.reject) }
                    FlagIcon(flag: .none, current: filterFlag) { toggleFlag(.none) }
                }
            }

            // 评分
            VStack(alignment: .leading, spacing: 8) {
                Text("评分 (≥)")
                    .font(UIStyle.captionFont)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= filterRating ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(star <= filterRating ? .yellow : .secondary.opacity(0.5))
                            .onTapGesture {
                                if filterRating == star {
                                    filterRating = 0
                                } else {
                                    filterRating = star
                                }
                            }
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                }
            }

            // 颜色
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
                    .font(UIStyle.captionFont)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    ForEach(ColorLabel.allCases.filter { $0 != .none }, id: \.rawValue) { label in
                        Circle()
                            .fill(Color(label.color))
                            .frame(width: 14, height: 14)
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
                            .scaleEffect(filterColorLabel == label ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3), value: filterColorLabel)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
        case .none: return "circle" // Or "flag.slash" if preferred
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
