## 布局调整
- 在 Folder Browser 模式下将根布局改为四列：左侧导航 → 树形文件夹 → 中央预览 → 右侧信息面板。
- 继续使用 HSplitView，多子视图组合实现四列；为每列设置合适的最小/理想宽度：
  - 左导航：min 160 / ideal 180 / max 300
  - 树形：min 220 / ideal 260 / max 380（根据目录深度可适当放宽）
  - 预览：flex，占据剩余空间
  - 右信息：min 220 / ideal 240 / max 450
- 非 Folder Browser 模式保持原三列结构不变。

## 交互行为
- 点击左侧导航中的“Folder”入口时：设置 viewMode = .folderBrowser，并将树形导航聚焦（可选：清空当前选中照片）。
- 树形导航：单击节点更新 filterFolder；双击展开/折叠；上下文菜单保留“在 Finder 显示”“从库移除”。
- 预览区：沿用 PhotoGridView，支持“包含子文件夹”开关、面包屑；双击进入单图模式，快捷键保持。
- 右侧信息面板：当有选中照片时显示详情，无选中时显示空态。

## 折叠/展示按钮
- 新增 @State: showLeftNav（默认 true）、showRightPanel（默认 true）。
- 左侧导航顶部加入一个折叠按钮（例如 chevron.left / chevron.right），点击切换 showLeftNav；折叠后保留一个窄边缘悬浮按钮用于“展开”。
- 右侧信息面板顶部加入折叠按钮，点击切换 showRightPanel；折叠后同样保留窄边缘悬浮按钮用于“展开”。
- 过渡使用 .animation(.spring(...)) 与 .transition(.move(edge: ...).combined(with: .opacity))，避免闪烁并保持一致风格。

## 状态与数据
- 选中目录：沿用 filterFolder 与 includeSubfolders 控制 filteredPhotos；树选择直接驱动预览。
- 视图模式：继续复用现有枚举，默认点击“Folder”进入 folderBrowser；单图/全屏行为不变。
- 滚动锚点与选中集：在切换到 folderBrowser 时清理 gridScrollAnchor；进入单图/全屏时按当前逻辑设置 currentPhoto。

## 组件改动
- ContentView：
  - 增加 showLeftNav、showRightPanel 状态；在 folderBrowser 分支下渲染四列，依据折叠状态动态包含/排除左右两列。
  - 左列继续使用 SidebarView；第二列渲染 FoldersTreeView；中间渲染 FolderPreviewView；右侧渲染 InfoPanelView。
  - ToolbarView 增加左右折叠的按钮（可选），与面板按钮形成双入口。
- SidebarView：
  - 增加“Folder”入口项；点击时设置 viewMode = .folderBrowser。
  - 顶部加入折叠按钮（与 ContentView 的 showLeftNav 绑定）。
- InfoPanelView 包装一层头部栏，加入折叠按钮（与 ContentView 的 showRightPanel 绑定）。

## 验证与细节
- 构建并运行：
  - 点击左侧“Folder”进入四列；树选择后预览更新；左右折叠按钮工作正常。
  - 切换到单图/全屏后左右折叠状态保持；返回 grid 时恢复。
- 边界：无媒体时预览显示空态；不可访问目录不崩溃；折叠时保留窄触发按钮防止不可恢复。
- 无障碍：为折叠按钮与树节点加上 accessibilityIdentifier 方便自动化测试。

## 变更范围
- 仅改动现有视图层（ContentView、SidebarView、InfoPanelView、ToolbarView），不改动数据模型与服务；保持与当前项目风格一致。