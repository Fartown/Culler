# 修复侧边栏导航选中状态 Bug

用户报告侧边栏中多个项目同时显示选中状态（特别是“文件夹”和“已拒绝”），且切换时表现不正常。这是由于 `isSelected` 的判断逻辑和点击操作未正确处理状态互斥导致的。

我将修改 `SidebarView.swift` 以确保：
1.  **“文件夹” (Folders)** 作为一个独立的模式，激活时应清除照片筛选条件。
2.  **“已选中” (Picked) / “已拒绝” (Rejected)** 筛选器在激活时应切换回网格视图，并与文件夹管理模式互斥。
3.  **“所有照片” (All Photos)** 正确重置所有状态。

## `SidebarView.swift` 修改计划

### 1. 更新 "Folders" 项目
- **操作**: 点击时，设置 `viewMode = .folderManagement`，`filterFlag = nil`，并 `filterFolder = nil`。
- **选中状态**: `viewMode == .folderManagement`。

### 2. 更新 "Picked" 项目
- **操作**: 点击时：
    - 如果当前处于 `.folderManagement` 模式，切换到 `.grid` 并清除 `filterFolder`。
    - 在 `.pick` 和 `nil` 之间切换 `filterFlag`。
- **选中状态**: `filterFlag == .pick` (且非文件夹管理模式)。

### 3. 更新 "Rejected" 项目
- **操作**: 与 "Picked" 类似，针对 `.reject`。
- **选中状态**: `filterFlag == .reject` (且非文件夹管理模式)。

### 4. 更新 "All Photos" 项目
- **操作**: 重置 `viewMode = .grid`，`filterFlag = nil`，`filterFolder = nil`。
- **选中状态**: `filterFlag == nil && filterFolder == nil && viewMode == .grid`。

这将确保点击“文件夹”时会取消“已拒绝”的选中状态（通过清除 flag），点击“已拒绝”时会取消“文件夹”的选中状态（通过切换视图模式）。
