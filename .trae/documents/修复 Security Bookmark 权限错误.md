# 从根本上解决 Security Bookmark 权限错误

这个错误的根本原因在于违反了 **macOS App Sandbox 的安全模型**：
**权限是授予用户明确选择的 URL（通常是文件夹）的，而不是授予其子文件的。**

当前代码的逻辑缺陷在于：
1. 用户选择了文件夹 A。
2. 代码遍历文件夹 A 得到文件 A/b.jpg。
3. 代码试图对 A/b.jpg 申请权限（`startAccessing...`）并创建书签。
4. **系统拒绝**，因为用户从未单独选择过 A/b.jpg，且此时并未处于文件夹 A 的“访问中”状态。

要从根本上解决这个问题，必须构建一套**基于“根授权 URL”的权限管理机制**，而不是基于文件路径。

## 核心修复计划

### 1. 建立“根授权”管理机制
不再仅仅存储文件路径，而是必须在内存中持久化保存用户通过 `NSOpenPanel` 或拖拽操作赋予权限的原始 `URL` 对象。

- **修改 `ImportView`**：
  - 新增 `@State private var authorizedURLs: [URL] = []`。
  - 此数组仅存储用户直接选择的、带有 Security Scope 的 URL。

### 2. 捕获并维护授权链
- **在 `addFilesFromURL` 中**：
  - 将用户选择的原始 URL（无论是文件还是文件夹）直接存入 `authorizedURLs`。
- **在清空操作中**：
  - 同步清空 `authorizedURLs`。

### 3. 重构权限获取逻辑 (核心算法)
在 `performImport` 中创建文件书签时，实施“**权限向上查找**”策略：

1. **查找授权父级**：对于任意待处理文件 `fileURL`，在 `authorizedURLs` 中查找其从属的“根 URL”（即 `fileURL` 路径包含 `rootURL` 路径）。
2. **激活父级权限**：调用根 URL 的 `startAccessingSecurityScopedResource()`。
3. **执行子文件操作**：在父级权限激活期间，对子文件 `fileURL` 执行 `bookmarkData(...)` 创建书签。
   - *注意：只要父级处于 Accessing 状态，子文件的操作即被允许。*
4. **释放父级权限**：操作完成后立即 `stopAccessingSecurityScopedResource()`。

### 4. 优化文件夹书签持久化
- 修改 `upsertImportedFolderBookmarks`，不再通过 `selectedFolderPaths`（字符串）重建 URL。
- 直接遍历 `authorizedURLs` 中的目录类型的 URL。
- 这样生成的文件夹书签才是真正持有沙盒权限的有效书签，确保 App 重启后依然能访问。

通过这套机制，应用将严格遵循沙盒规范：**以用户授权点为根，按需激活权限覆盖子资源**，从而彻底消除 Permission error。
