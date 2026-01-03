## 目标
- 将所有筛选入口收敛到左侧面板，形成“导航 + 筛选”的单一工作区
- 保持信息密度合理（折叠分区、统一控件尺寸），操作路径更短、更稳定
- 与现有数据状态完全兼容（filterFlag/filterRating/filterColorLabel）

## 布局与交互
- 左栏结构：
  1) 图库（全部照片）
  2) 文件夹（含“包含子文件夹”开关）
  3) 相册集合
  4) 筛选（新增分区，默认展开，可折叠）
- 筛选分区内容：
  - 头部：标题“筛选” + “清除”按钮（禁用态逻辑沿用 hasActiveFilters）
  - 旗标：已选 / 已拒 / 未标记（Chip）
  - 评分（至少）：0~5（Chip），0 表示全部
  - 颜色标签：圆点选择（含“无”）
- 折叠与偏好：筛选分区折叠状态使用 AppStorage 记忆；与其它分区一致
- 行为：
  - 点击筛选即刻更新 ContentView 的 filterFlag/filterRating/filterColorLabel，触发中间内容刷新
  - 清除按钮重用 ContentView.clearFilters()

## 去重与职责
- 右侧检查器仅保留“信息”页，移除“筛选”页
- 底部工具条保留唯一“编辑/打标”入口
- 左栏不再出现旗标型导航项（已选/已拒），使用筛选分区替代

## 代码改动
- 新增组件：SidebarFiltersView.swift（左栏筛选 UI）
  - 复用 FilterChip；如需通用，将其抽取到 Views/Components/FilterChip.swift
- 修改：SidebarView.swift
  - 在列表末尾加入 DisclosureGroup("筛选")，嵌入 SidebarFiltersView，绑定到 ContentView 的 filter* 状态与 clearFilters()
  - 折叠状态 @AppStorage("expandFilters")
- 修改：InspectorView.swift
  - 移除筛选分段页；仅保留信息面板与空态
- 修改：ContentView.swift
  - 更新 inspectorColumn 的构建（不再传筛选绑定）
  - 保持 ToolbarView 的“清除筛选”按钮原逻辑

## 参考位置
- 左栏与当前结构：[SidebarView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/SidebarView.swift)
- 检查器与信息面板：[InspectorView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/InspectorView.swift)、[InfoPanelView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/InfoPanelView.swift)
- 主视图状态与清除逻辑：[ContentView.swift:L101-L105](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L101-L105)、[ContentView.swift:filteredPhotos](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L64-L71)

## 验证
- 编译与运行：确认左栏筛选生效、清除按钮工作、折叠状态持久化
- 回归：移除右侧筛选后不影响信息显示；底部编辑入口正常工作
- 可选：在 ToolbarView 显示筛选摘要（例如“评分≥3，颜色：红”）

## 交付
- 左栏集中筛选的实现文件与样式
- 更新后的 SidebarView/InspectorView/ContentView
- 简短使用说明与前后对比截图