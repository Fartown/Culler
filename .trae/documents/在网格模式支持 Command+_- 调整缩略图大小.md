## 目标
- 在“网格模式”中，通过 Command+ 和 Command- 快捷键动态调整每个缩略图（网格单元）的大小，提供与单图模式一致的缩放体验，并支持重置。

## 现状与切入点
- 网格视图：PhotoGridView 使用 `thumbnailSize` 控制缩略图尺寸，布局为 `LazyVGrid`，缩略图直接 `frame(width: size, height: size)`。
  - 参考：[PhotoGridView.swift:L4-L16](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/PhotoGridView.swift#L4-L16)、[PhotoGridView.swift:L32-L40](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/PhotoGridView.swift#L32-L40)、[PhotoGridView.swift:L164-L176](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/PhotoGridView.swift#L164-L176)
- 键盘层：已有全局拦截将 Command+=、Command-、Command+0 转为通知 `.zoomIn/.zoomOut/.zoomReset`。
  - 参考：[KeyboardShortcutManager.swift:L46-L63](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Services/KeyboardShortcutManager.swift#L46-L63)、通知定义 [CullerApp.swift:L91-L109](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/CullerApp.swift#L91-L109)
- 单图视图已监听这些通知并调整缩放；网格视图目前未监听。
  - 参考：[SinglePhotoView.swift:L205-L221](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/SinglePhotoView.swift#L205-L221)

## 方案概览
- 在 PhotoGridView 中监听 `.zoomIn/.zoomOut/.zoomReset` 通知，按比例增减 `thumbnailSize` 并限制范围；重置恢复默认值。
- 可选增加菜单命令（View/Zoom）绑定相同通知与快捷键，提升可发现性与一致性。
- 可选持久化网格缩略图大小到 `AppStorage`，保持用户偏好。

## 详细实现
- 在 PhotoGridView 增加通知监听与尺寸调整函数：

```swift
@State private var thumbnailSize: CGFloat = 150
private let minThumb: CGFloat = 80
private let maxThumb: CGFloat = 300
private let zoomStep: CGFloat = 1.1

private func adjustThumbnailSize(increase: Bool) {
    let next = increase ? thumbnailSize * zoomStep : thumbnailSize / zoomStep
    thumbnailSize = max(min(next, maxThumb), minThumb)
}

var body: some View {
    content
    .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
        adjustThumbnailSize(increase: true)
    }
    .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
        adjustThumbnailSize(increase: false)
    }
    .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
        thumbnailSize = 150
    }
}
```
- 说明：
  - 采用乘法步进（1.1）获得平滑缩放体验；边界 80–300 保障布局稳定。
  - 网格行列计算依赖 `thumbnailSize`，变更后会自动重新布局（已使用 `GeometryReader` 与状态驱动）。

- 可选：在 CullerApp 的 `commands` 中增加菜单项，复用通知与快捷键（加号需使用“= + Shift”）：

```swift
CommandMenu("View") {
    Button("Zoom In") {
        NotificationCenter.default.post(name: .zoomIn, object: nil)
    }.keyboardShortcut("=", modifiers: [.command, .shift])

    Button("Zoom Out") {
        NotificationCenter.default.post(name: .zoomOut, object: nil)
    }.keyboardShortcut("-", modifiers: [.command])

    Button("Actual Size") {
        NotificationCenter.default.post(name: .zoomReset, object: nil)
    }.keyboardShortcut("0", modifiers: [.command])
}
```
- 可选：持久化用户偏好
  - 将 `thumbnailSize` 替换为 `@AppStorage("gridThumbnailSize") var thumbnailSize: Double = 150`（或通过视图模型），并使用相同边界与步进。首次运行使用默认值，调整后自动保存。

## 验证
- 在网格模式下按 Command+/-，观察缩略图尺寸变化与行列数变化，确保平滑且边界正确。
- 按 Command+0 恢复默认大小，验证与单图模式一致性。
- 调整窗口宽度后，确认自适应布局未破坏（`LazyVGrid` 仍正常）。
- 验证方向键导航与选择逻辑不受影响（参考 [PhotoGridView.swift:L108-L123](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/PhotoGridView.swift#L108-L123)）。

## 兼容性与注意事项
- Plus 键等效为 `"=" + .shift`；已有键盘管理器会发出统一通知，无需重复处理物理键位。
- 与现有 `GridItem(.adaptive(minimum: 150, maximum: 200))` 的容器宽度限制不冲突；缩略图自身尺寸以状态为准。

## 交付与回滚
- 变更局限于 PhotoGridView 与可选 Commands；若出现问题，移除 `.onReceive` 即可回滚为现状。