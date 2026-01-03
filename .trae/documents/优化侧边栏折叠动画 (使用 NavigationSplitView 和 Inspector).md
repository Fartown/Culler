为解决左右侧边栏折叠时的布局跳变问题，我计划将当前的 `HSplitView` 布局重构为 macOS 14+ 原生的 `NavigationSplitView` 和 `.inspector` 修饰符。这将利用系统原生的动画效果来实现平滑的展开和折叠。

### 修改计划：`Culler/Culler/Views/ContentView.swift`

1.  **引入 `NavigationSplitViewVisibility` 状态**
    - 新增 `@State private var columnVisibility: NavigationSplitViewVisibility = .all` 来控制左侧栏显示。
    - 添加 `onChange(of: showLeftNav)` 和 `onChange(of: columnVisibility)` 以同步 `showLeftNav`（布尔值）和 `columnVisibility`（枚举值）的状态。

2.  **重构 `splitLayout`**
    - 移除 `HSplitView`。
    - 使用 `NavigationSplitView(columnVisibility: $columnVisibility)`：
        - **Sidebar**: 放置 `sidebarColumn`。
        - **Detail**: 放置 `mainColumn`，并对其应用 `.inspector(isPresented: $showRightPanel)` 来显示右侧栏。

3.  **调整 `sidebarColumn`**
    - 移除 `if showLeftNav` 判断（交由 `NavigationSplitView` 控制）。
    - 将 `.frame(minWidth: ...)` 替换为 `.navigationSplitViewColumnWidth(min:ideal:max:)`。
    - 移除 `.layoutPriority(0)`。

4.  **调整 `inspectorColumn`**
    - 移除 `if showRightPanel` 判断（交由 `.inspector` 控制）。
    - 将 `.frame(minWidth: ...)` 替换为 `.inspectorColumnWidth(min:ideal:max:)`。
    - 移除 `.layoutPriority(0)`。

5.  **调整 `mainColumn`**
    - 移除 `.layoutPriority(1)`（`NavigationSplitView` 会自动处理）。

### 预期效果
- **左侧栏**：折叠/展开时将有平滑的滑动动画，不再造成中间内容瞬间跳动。
- **右侧栏**：使用 `.inspector` 后，右侧面板将以覆盖或挤压的方式平滑进出，消除跳变。
- **兼容性**：项目已引入 `SwiftData`，确认为 macOS 14+ 环境，完全支持上述原生组件。
