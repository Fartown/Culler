## 目标与定位
- 目标：让图片浏览模式下的底部工具栏（Tab栏）在所有窗口宽度下完整展示功能按钮，点击舒适，视觉层次清晰，并具备细腻的交互动画，保持与整体风格一致。
- 代码定位：
  - 组合挂载位置：在 ContentView 中挂载底部标注工具栏 [ContentView.swift:L132-L137](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L132-L137)
  - 顶端模式切换栏： [ToolbarView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ToolbarView.swift)
  - 底部标注工具栏主文件： [MarkingToolbar.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/MarkingToolbar.swift)
  - 相关浏览视图：网格 [PhotoGridView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift)、单图 [SinglePhotoView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/SinglePhotoView.swift)、全屏 [FullscreenView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/FullscreenView.swift)

## 总体设计方案
- 使用 LazyVGrid(.adaptive) 重构底部栏的按钮布局，自动换行，确保所有功能完整显示。
- 通过 safeAreaInset(edge: .bottom) 挂载底部栏，获得一致的底部沉浸与安全区处理。
- 统一高度与间距，确保“易点按”的最小命中尺寸。
- 保持与现有主题色、圆角与材质风格一致；提升图标/文字层次。
- 为点击、悬停与状态切换添加轻量动画，提升交互反馈。

## 布局与结构改造
- 将 MarkingToolbar 中当前的 ViewThatFits(HStack/VStack) 改为 LazyVGrid，自适应列数：
  - 列定义：GridItem(.adaptive, minimum: 72, maximum: 120, spacing: 12)
  - 好处：空间不足时自然换行，避免“显示不全/被截断”。
- 结构分区：
  - 上层：选中计数与批量操作（如“全部选择/清除”）
  - 下层：Flag / Rating / Color 等功能按钮网格；或将计数置于最左，按钮自适应占满其余空间。
- 在 ContentView 中使用 safeAreaInset(edge: .bottom) 包裹 MarkingToolbar，以便在不同视图模式（网格/单图/全屏）下统一表现。

## 高度与间距规范
- 按钮最小点击高度：36–40pt；宽度由网格自适应保证不小于 72pt。
- 行间距：12pt；内边距：水平 16–20pt，垂直 8–10pt。
- 按钮内容（图标+文字）间距：6–8pt；外层圆角：6–8pt。

## 屏幕适配策略
- 使用 LazyVGrid(.adaptive) 保证在窄宽窗口下自动换行，宽窗下单行铺满，避免溢出。
- 如按钮数量过多且换行仍有压力，允许底部区域纵向增高到 56–72pt，并保持控件间距不变，优先保障完整显示。
- 在超窄窗口下，计数文本缩略（例如 "99+"），维持布局稳定。

## 视觉层次优化
- 图标：统一 SF Symbols 尺寸 16–18pt；文字：系统正文 13–14pt。
- 颜色：沿用现有主题（与 ToolbarView/MarkingToolbar 保持一致），选中态使用强调色/半透明背景提高对比度。
- 背景：使用现有深色背景 [MarkingToolbar.swift:L59-L63](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/MarkingToolbar.swift#L59-L63) 或 material 效果，添加 1px 顶部分隔线降低与内容区的竞争。
- 统一圆角与阴影级别，避免与顶端 ToolbarView 视觉冲突。

## 动画与交互反馈
- 点击动画：.easeOut(0.18) 的轻微缩放（0.96→1.0）。
- 悬停动画（macOS）：onHover 切换 .scaleEffect 与背景高亮，.easeInOut(0.15)。
- 状态切换（如评分/标签变更）：withAnimation(.spring(response: 0.25, dampingFraction: 0.9))。
- 布局变化过渡：.transition(.opacity.combined(with: .move(edge: .bottom))) 在列数变化时更平滑。

## 与应用风格一致性
- 复用现有颜色与扩展（NSColor(hex:)）与圆角/内边距约定，匹配 ToolbarView 的色板与层次。
- 选中态/悬浮态的颜色与透明度遵循当前顶端 Toolbar 的选中风格，实现全局一致。

## 具体改动点（不执行，仅列计划）
- MarkingToolbar.swift：
  - 替换 ViewThatFits 布局为 LazyVGrid(.adaptive)；设定列最小/最大宽度与统一间距。
  - 封装通用 ToolbarItemView（图标+文案+选中态）以复用样式，统一命中区域与动画。
  - 为计数文本添加最小/最大宽度与缩略策略（超窄窗口显示 "99+"）。
  - 背景与分隔线：沿用现有配色，增加顶部分隔线与轻微阴影。
- ContentView.swift：
  - 改为 safeAreaInset(edge: .bottom) 挂载 MarkingToolbar，统一与内容区的关系。[ContentView.swift:L132-L137](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L132-L137)
  - 确保在单图/全屏模式下底部栏不与内容发生遮挡；必要时使用 .padding(.bottom) 平衡。
- ToolbarView.swift：
  - 对按钮尺寸与文字字号与选中态做统一（与底部栏一致的系统字号与圆角）。

## 验证与测试清单
- 不同窗口宽度（极窄、常规、超宽）下，所有按钮完整显示，无溢出或遮挡。
- 三个视图模式（网格/单图/全屏）切换时，底部栏位置、背景与分隔线表现一致。
- 点击/悬停动画平滑，选中态明显；无闪烁、无过度缩放。
- 计数文本在大规模选择时仍可读（缩略策略生效）。
- 通过 VoiceOver/可达性检查命中区域是否达标；光标与键盘导航正常。

---
如确认以上方案，我将按上述改动点实施代码更新，并在完成后进行可视化验证与交互细节打磨。