我将实现单图预览中的双指上下拖拽（滚动）缩放功能。

1. **创建** **`ScrollReader`** **视图组件**:

   * 在 `SinglePhotoView.swift` 中添加遵循 `NSViewRepresentable` 的 `ScrollReader` 结构体。

   * 该组件将使用 `NSEvent.addLocalMonitorForEvents` 监听滚动事件。

   * 通过重写 `hitTest` 返回 `nil`，确保点击事件能穿透传递给底层的图片和按钮（不影响现有的双击、拖拽功能）。

   * 在回调中检查鼠标位置是否在视图范围内，确保仅在光标位于查看器区域时触发缩放。

2. **集成到** **`SinglePhotoView`**:

   * 将 `ScrollReader` 覆盖在 `SinglePhotoView` 的主 `ZStack` 上。

   * 在 `onScroll` 回调中实现缩放逻辑，更新 `scale` 和 `baseScale`。

   * 采用连续缩放算法：`newScale = currentScale * (1 + delta * sensitivity)`，实现平滑的缩放体验。

3. **缩放逻辑优化**:

   * 优先使用 `scrollingDeltaY` 以支持高精度的触控板手势。

   * 同步更新 `baseScale`，确保与现有的捏合手势（MagnificationGesture）无缝衔接。

   * 设置合理的缩放范围（0.5x - 5.0x）。

