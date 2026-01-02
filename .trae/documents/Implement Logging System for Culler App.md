# 为 Culler App 实现日志与问题排查系统

## 1. 核心日志服务 (Logger Service)
创建 `Culler/Culler/Services/Logger.swift`，负责底层的日志写入与文件管理。

### 核心功能
*   **单例访问**: `Logger.shared`。
*   **文件存储**: 
    *   路径: `FileManager.default.urls(for: .applicationSupportDirectory, ...)` 下的 `Logs` 子目录。
    *   命名: `log_yyyy-MM-dd.txt` (按天分割，如 `log_2023-10-27.txt`)。
*   **日志格式**:
    *   `[HH:mm:ss.SSS] [Level] [Category] Message`
    *   Level: `INFO`, `WARN`, `ERROR`, `DEBUG`
*   **智能轮转 (Log Rotation)**:
    *   **触发时机**: App 启动时及每次写入日志后。
    *   **策略**: 计算 Logs 目录总大小。如果超过 **20MB**，按修改时间升序（最旧在前）删除文件，直到总大小低于 20MB。
*   **异步写入**: 使用 `DispatchQueue(label: "com.culler.logger")` 避免阻塞主线程。

## 2. 日志查看器 (Log Viewer UI)
创建 `Culler/Culler/Views/LogViewer` 目录，包含以下文件：

### `LogViewer.swift`
使用 `NavigationSplitView` 构建的双栏界面：
*   **左侧列表 (Sidebar)**:
    *   列出所有 `.txt` 日志文件。
    *   显示文件名和文件大小。
    *   按修改时间降序排列（最新的在上面）。
*   **右侧详情 (Detail)**:
    *   使用 `TextEditor` 或 `ScrollView` 显示日志内容。
    *   支持大文本的性能优化（如果需要）。
*   **工具栏 (Toolbar)**:
    *   **Refresh**: 重新扫描目录。
    *   **Delete**: 删除当前文件。
    *   **Reveal**: 在 Finder 中显示。
    *   **Clear All**: 清空所有日志。

## 3. 全局集成与埋点 (Integration & Logging)

### 入口集成 (`CullerApp.swift`)
1.  **初始化**: 在 `init()` 中调用 `Logger.shared.info("App Launched", category: "Lifecycle")`。
2.  **新窗口**: 添加 `WindowGroup(id: "logViewer") { LogViewer() }`。
3.  **菜单项**: 在 `CommandMenu("Help")` 中添加 `Button("View Logs")`，调用 `openWindow(id: "logViewer")`。

### 业务埋点 (Logging Points)
将在以下关键路径添加日志：

1.  **用户交互 (`ContentView.swift`)**:
    *   **导入**: 当接收到 `.importPhotos` 通知时，记录 `"UI: User triggered Import Photos"`。
    *   **标记**: 在 `setFlagForSelected` 中，记录 `"Action: Set flag [\(flag)] for [\(count)] photos"`。
    *   **评分**: 在 `setRatingForSelected` 中，记录 `"Action: Set rating [\(rating)] for [\(count)] photos"`。
    *   **视图切换**: 记录视图模式切换（Grid/Single/Fullscreen）。

2.  **核心服务 (`ThumbnailService.swift`)**:
    *   **错误**: 在 `generateThumbnail` 失败时，记录 `"Error: Thumbnail generation failed for [\(url.lastPathComponent)]: \(error)"`。
    *   **性能**: (可选) 记录大图生成的耗时。

## 4. 验证与测试
1.  **运行 App**: 启动 App，执行导入、评分操作，确保日志文件生成。
2.  **查看器测试**: 打开 "Help -> View Logs"，确认能看到刚才的操作日志。
3.  **轮转测试**: 
    *   手动复制大文件到 Logs 目录（模拟超过 20MB）。
    *   重启 App 或触发新日志，验证旧文件被删除，且总大小回落到 20MB 以下。
