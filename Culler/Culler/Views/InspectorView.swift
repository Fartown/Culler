import SwiftUI

struct InspectorView: View {
    let photo: Photo?
    @Binding var filterFlag: Flag?
    @Binding var filterRating: Int
    @Binding var filterColorLabel: ColorLabel?
    let onClearFilters: () -> Void

    @State private var expandInfo: Bool = true
    @State private var expandFilters: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DisclosureGroup(isExpanded: $expandInfo) {
                    if let photo {
                        InfoPanelView(photo: photo)
                    } else {
                        EmptyStateView(systemImage: "info.circle", title: "未选择照片", subtitle: "选择一张照片后这里会显示详细信息")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                } label: {
                    Text("信息")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                DisclosureGroup(isExpanded: $expandFilters) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("筛选")
                                .font(.headline)
                            Spacer()
                            Button("清除") { onClearFilters() }
                                .disabled(!hasActiveFilters)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("旗标")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                FilterChip(title: "已选", isActive: filterFlag == .pick) {
                                    filterFlag = (filterFlag == .pick) ? nil : .pick
                                }
                                FilterChip(title: "已拒", isActive: filterFlag == .reject) {
                                    filterFlag = (filterFlag == .reject) ? nil : .reject
                                }
                                FilterChip(title: "未标记", isActive: filterFlag == .none) {
                                    filterFlag = (filterFlag == .none) ? nil : .none
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("评分（至少）")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                ForEach(0...5, id: \.self) { rating in
                                    let title = (rating == 0) ? "全部" : "\(rating)★"
                                    FilterChip(title: title, isActive: filterRating == rating) {
                                        filterRating = rating
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("颜色标签")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 10) {
                                ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                                    if label == .none {
                                        FilterChip(title: "无", isActive: filterColorLabel == nil) {
                                            filterColorLabel = nil
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color(label.color))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Circle()
                                                    .stroke(filterColorLabel == label ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                filterColorLabel = (filterColorLabel == label) ? nil : label
                                            }
                                            .accessibilityLabel(label.name)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } label: {
                    Text("筛选")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color(NSColor(hex: "#252525")))
    }

    private var hasActiveFilters: Bool {
        filterFlag != nil || filterRating > 0 || filterColorLabel != nil
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? Color.accentColor.opacity(0.9) : Color(NSColor(hex: "#2a2a2a")))
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
