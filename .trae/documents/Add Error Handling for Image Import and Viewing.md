# 全面的异常处理与错误提示机制

我将为 Culler 应用构建一个完整的异常处理系统，覆盖从导入到查看的各个环节，确保所有潜在错误都能被捕获并向用户提供清晰的反馈。

## 1. 核心错误模型定义 (`Models/AppErrors.swift`)
建立统一的错误类型，以便在 UI 层进行标准化展示。
*   **`ImageLoadError` (图片加载错误)**:
    *   `fileNotFound`: 原文件被移动或删除。
    *   `permissionDenied`: 应用丢失了文件访问权限（沙盒限制）。
    *   `corruptedData`: 文件头损坏或数据不完整，无法解码。
    *   `unsupportedFormat`: 虽然扩展名匹配，但实际格式不支持。
*   **`ImportError` (导入错误)**:
    *   `sourceAccessDenied`: 无法读取源文件。
    *   `destinationWriteFailed`: 无法写入库目录（如磁盘已满、权限不足）。
    *   `bookmarkCreationFailure`: 无法创建安全书签（导致下次启动无法访问）。

## 2. 增强图片服务 (`Services/ThumbnailService.swift`)
改造图片加载逻辑，使其具备“诊断能力”。
*   将返回值从 `NSImage?` 升级为 `Result<NSImage, ImageLoadError>`。
*   **增加前置检查**:
    *   在加载前验证 `FileManager.fileExists`。
    *   验证 Security Scoped Bookmark 是否成功激活。
*   **错误透传**: 将底层 API（如 `CGImageSource`）的失败原因转换为上层可读的错误枚举。

## 3. 完善导入流程 (`Views/ImportView.swift`)
确保导入过程中的任何失败都不会被静默忽略。
*   **错误收集**: 引入 `importErrors` 队列，记录所有失败的文件名和具体原因。
*   **场景覆盖**:
    *   **复制模式**: 捕获磁盘空间不足 (Disk Full) 和 写入权限错误。
    *   **引用模式**: 捕获书签创建失败，提示用户可能需要重新授权。
*   **结果反馈**: 导入完成后，如果存在失败项，弹出一个详细的**错误报告对话框**，列出“成功 X 张，失败 Y 张”，并展示失败文件的列表。

## 4. 优化查看体验 (`Views/SinglePhotoView.swift` & `PhotoGridView.swift`)
*   **缩略图**: 当加载失败时，根据错误类型显示不同图标（如“文件丢失”显示问号，“损坏”显示感叹号），不再显示空白或无限加载。
*   **大图查看**:
    *   添加 `loadError` 状态管理。
    *   设计一个**错误提示视图**替代加载圈：包含错误图标、错误标题（如“无法加载图片”）和详细原因（如“原文件路径不存在”），让用户知道发生了什么。
