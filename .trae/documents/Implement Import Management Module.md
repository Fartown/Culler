# 导入管理模块实施计划

我将实现一个“导入管理”模块，允许用户按源文件夹查看和管理照片。这将涉及创建新视图、更新侧边栏导航以及增强主内容视图以支持基于文件夹的筛选。

## 1. 创建 `ImportManagementView`
该视图将负责列出所有导入的文件夹并提供管理选项。
- **功能**:
  - 自动按父目录路径分组所有现有照片。
  - 显示源文件夹列表及照片数量。
  - **操作**:
    - **查看**: 筛选主网格以显示特定文件夹中的照片。
    - **在 Finder 中显示**: 打开源文件夹。
    - **移除**: 从库中移除属于某文件夹的所有照片（仅从数据库移除）。

## 2. 更新 `ContentView`
集成新视图并添加对文件夹筛选的支持。
- **状态更新**:
  - 在 `ViewMode` 枚举中添加 `case folderManagement`。
  - 添加 `@State private var filterFolder: String?` 以跟踪当前选定的文件夹筛选。
- **逻辑更新**:
  - 更新 `filteredPhotos` 以支持 `filterFolder` 筛选。
  - 在主 `ZStack` 中，当 `viewMode` 为 `.folderManagement` 时显示 `ImportManagementView`。
  - 将 `viewMode` 绑定传递给 `SidebarView`。

## 3. 更新 `SidebarView`
启用对新模块的导航。
- **UI 更新**:
  - 在侧边栏添加“导入管理”选项。
  - 添加 `viewMode` 绑定以控制导航。
  - 更新“所有照片”操作以清除文件夹筛选并切换回网格模式。

## 实施步骤
1.  **创建** `Culler/Culler/Culler/Views/ImportManagementView.swift`。
2.  **修改** `Culler/Culler/Culler/Views/ContentView.swift` 以添加状态和路由逻辑。
3.  **修改** `Culler/Culler/Culler/Views/SidebarView.swift` 以添加菜单项。
