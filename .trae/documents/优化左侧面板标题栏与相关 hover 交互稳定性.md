## 问题定位
- 左侧面板标题（Sidebar/Sections）未使用 hover，布局静态：[SidebarView.swift:L240-L247](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/SidebarView.swift#L240-L247)、[Sections.swift:L14-L20](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/Sections.swift#L14-L20)。
- 顶部工具栏排序菜单的胶囊按钮为 Menu，可能因样式在 hover 时发生几何变化：[ToolbarView.swift:L66-L103](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/ToolbarView.swift#L66-L103)。
- MarkingToolbar 的按钮在 hover/按压时存在缩放动画，易引起视觉“移动”与命中区不稳定：[MarkingToolbar.swift:L185-L204](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/MarkingToolbar.swift#L185-L204)、[PressableButtonStyle:L177-L183](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/MarkingToolbar.swift#L177-L183)。

## 设计原则
- hover 反馈不应改变几何布局与命中区域。
- 固定交互控件的最小尺寸与 contentShape，避免抖动。
- 降低或移除 hover/press 的尺寸动画，用颜色/阴影替代。

## 修改方案
- ToolbarView（排序菜单胶囊）
  - 为 Menu 的 label 设定固定高度与命中区域，避免 hover 样式影响布局。
  - 将 .menuStyle(.borderlessButton) 改为 .menuStyle(.button)，减少系统样式引入的尺寸/边距变化。
  - 设定最小宽度以避免不同文案导致的轻微抖动。
  - 变更示例：

    ```swift
    Menu { /* 原有内容 */ } label: {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up.arrow.down").font(.system(size: 12)).foregroundColor(.secondary)
            Text(sortOption.title).font(.system(size: 13)).foregroundColor(.primary).fixedSize()
            Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary.opacity(0.5))
        }
        .frame(minWidth: 90, height: 28)
        .contentShape(Rectangle())
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
    .menuStyle(.button)
    ```

- MarkingToolbar（按钮 hover/按压反馈）
  - 移除 hover 的 scaleEffect，改用边框或阴影，不改变几何尺寸。
  - 固定命中区域为矩形，保留固定 frame。
  - 将按压动画由缩放改为轻微透明度变化。
  - 变更示例：

    ```swift
    // ToolbarItemView
    content
        .padding(.horizontal, fixedWidth == nil ? 8 : 0)
        .frame(width: fixedWidth, height: 40)
        .background(Color(NSColor(hex: "#2a2a2a")))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(hovering ? Color.primary.opacity(0.15) : Color.clear, lineWidth: 1))
        .shadow(color: hovering ? Color.black.opacity(0.2) : Color.clear, radius: 3, x: 0, y: 1)
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }

    // PressableButtonStyle
    configuration.label
        .opacity(configuration.isPressed ? 0.85 : 1)
        .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    ```

- FoldersTreeView（行 hover 背景）
  - 当前仅改变背景 fill，不影响布局；保持不变。如出现抖动，再将背景改为 overlay 并确认 contentShape 已覆盖整行：[FoldersTreeView.swift:L53-L61](file:///Users/zhangchao/workspace/dev/Culler/Culler/Culler/Views/FoldersTreeView.swift#L53-L61)。

## 验证方法
- 手动测试：在 macOS 上分别对左侧标题栏、排序菜单胶囊、标注工具条进行悬停与点击，确认不再出现“移动/抖动”，命中区域稳定。
- 交互一致性：切换不同排序文案，观察控件宽度是否保持稳定；快速移入移出 hover，确认无尺寸动画。

## 风险与回滚
- 改为 .menuStyle(.button) 可能改变胶囊的系统高亮样式，但不影响功能；如视觉不满意可回退到 .borderlessButton 并继续固定 frame/contentShape。
- 去除缩放后 hover 反馈更轻微，如需更强感受可提高阴影或边框透明度。
- 所有改动均局部且可单独回滚。