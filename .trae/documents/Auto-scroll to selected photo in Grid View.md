问题在于 `PhotoGridView` 目前仅在 `scrollAnchor` 变化时才会滚动，而在网格内进行导航（如使用键盘方向键）导致选中照片（`currentPhoto`）变化时，并没有触发滚动逻辑。

### 修复方案
我将修改 `Culler/Culler/Views/PhotoGridView.swift` 文件，确保当选中照片发生变化时，网格视图会自动滚动以保持选中项可见，并将其置于屏幕中央。

**具体修改：**
1.  在 `PhotoGridView.swift` 的 `ScrollViewReader` 代码块中，添加一个 `.onChange(of: currentPhoto)` 修饰符。
2.  在这个 `onChange` 块中，调用 `proxy.scrollTo(photo.id, anchor: .center)` 来滚动到新选中的照片。
    *   **关键调整**：根据您的要求，我会明确指定 `anchor: .center`。这意味着每当选中新的照片时，如果触发滚动，系统会尝试将该照片置于视图的垂直居中位置。

这样修改后，当您在网格模式下选中了屏幕外的照片，视图会自动滚动并将该照片显示在屏幕中央。