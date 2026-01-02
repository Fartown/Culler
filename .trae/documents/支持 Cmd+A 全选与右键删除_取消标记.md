**功能概述**

* 在照片网格中支持 Command + A 全选当前筛选结果。

* 右键菜单支持：从磁盘删除、从导入删除、取消标记（Flag 置为 none），并在多选时对所有选中项生效。

**实现方案**

* 全选（Command+A）：

  * 在通知扩展中添加 Notification.Name.selectAll（位置：[CullerApp.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/CullerApp.swift#L82-L91)）。

  * 在键盘管理器识别 Cmd+A：调整修饰键过滤逻辑，单独捕获 \[.command] + "a"，派发 .selectAll（位置：[KeyboardShortcutManager.handle](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Services/KeyboardShortcutManager.swift#L23-L78)）。

  * 在 ContentView 订阅 .selectAll：selectedPhotos = Set(filteredPhotos.map { $0.id })（位置：[ContentView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L135-L147) 附近）。

* 右键菜单（单/多选生效）：

  * 在网格视图将上下文菜单由单张 photo 改为 selection-aware：如果当前右键项在选中集合中，则将目标集合设为所有选中项，否则只针对该项。将该目标集合传入菜单组件（位置：[PhotoGridView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L35-L39)）。

  * 菜单项实现：

    * 取消标记：将目标集合的 flag 统一置为 .none。

    * 从导入删除：仅删除 SwiftData 模型对象 modelContext.delete(photo)，不触碰磁盘（参考文件夹删除逻辑：[ImportView.deleteFolder](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ImportView.swift#L409-L416)）。

    * 从磁盘删除：对每个目标 photo：

      * 取得 photo.fileURL，按需 startAccessingSecurityScopedResource。

      * FileManager.default.removeItem(at: url) 删除文件；随后 modelContext.delete(photo)。

    * 保留原有 Flag/Rating/Color 子菜单与 “Show in Finder”。

  * 在菜单视图中注入 @Environment(.modelContext) 以执行删除。

**代码改动点**

* 添加通知名：selectAll（[CullerApp.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/CullerApp.swift#L82-L91)）。

* 键盘：在 KeyboardShortcutManager 中专门处理 Cmd+A，不再被修饰键过滤短路（[KeyboardShortcutManager.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Services/KeyboardShortcutManager.swift#L31-L36) 与分支 \[L38-L59]）。

* 视图：ContentView 订阅通知并更新 selectedPhotos（[ContentView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L135-L154)）。

* 网格：PhotoGridView 的 contextMenu 传递目标集合；PhotoContextMenu 接收 \[Photo] 并执行批量操作（[PhotoGridView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L35-L39)、[PhotoContextMenu.swift 区块](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L275-L309)）。

**交互与边界**

* 多选优先：右键作用于选中集合；若右键对象未被选中，则只作用该对象。

* 删除确认：当前按 MVP 实现为直接删除；如需确认弹窗可后续补充。

* 磁盘删除失败（权限或文件不存在）时跳过该项；不影响其他项。

**验证**

* 在网格视图中按 Cmd+A，selectedPhotos 数量等于 filteredPhotos 数量。

* 多选情况下右键选择 “取消标记/从导入删除/从磁盘删除” 对所有选中项生效，UI 刷新；单选时只影响该项。

* “从导入删除”不影响磁盘文件；“从磁盘删除”后文件不存在且模型对象移除。

