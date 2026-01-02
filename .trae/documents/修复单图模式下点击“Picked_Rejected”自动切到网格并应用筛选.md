## 问题定位
- 单图模式下点击侧边栏“Picked/Rejected”没有切回网格；仅更新了 filterFlag，导致仍停留在单图视图，体验与预期不符。
- 筛选逻辑本身在 ContentView.filteredPhotos 已正确依据 flag 过滤，但由于视图未切换，用户看不到筛选生效结果。
- 可能存在状态不同步：切到网格后右侧信息面板仍显示上一张单图（currentPhoto 未清理）；选中集合可能包含不在筛选结果中的照片。

## 修改方案
1. 侧边栏点击行为（Picked/Rejected）在单图/全屏时强制切到网格，并带过渡动画：
   - 在 SidebarView 的 “Picked/Rejected” 项点击回调中，若 viewMode 是 .single 或 .fullscreen，则使用 withAnimation(.easeInOut) { viewMode = .grid }，随后设置 filterFlag。
   - 保持现有在文件夹管理模式下的处理（退出文件夹管理并清空 filterFolder）。
   - 参考位置：[SidebarView.swift:Picked/Rejected 项](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/SidebarView.swift#L57-L70)

2. 视图模式切换时的状态同步：
   - 在 ContentView 的 onChange(of: viewMode) 增加对 .grid 的分支：切换到网格时清理 currentPhoto，确保信息面板与选择依据网格视图状态；同时将 selectedPhotos 与筛选结果求交集，移除不可见项，避免后续操作作用在不可见照片上。
   - 参考位置：[ContentView.swift:onChange(viewMode)](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L150-L156)

3. 筛选与排序：
   - 筛选继续使用现有 filteredPhotos（按 filterFlag、rating、color、folder 组合过滤）。无需改动排序，保持 @Query photos 的原始顺序，即满足“按原始排序规则”。
   - 参考位置：[ContentView.swift:filteredPhotos](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L25-L44)

4. 过渡动画与交互：
   - 仅对从单图/全屏切到网格的视图模式更改添加 withAnimation(.easeInOut)。网格布局与交互（选择、双击、上下左右导航、悬停快操作）保持不变。
   - 参考位置：
     - [PhotoGridView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift)
     - [SinglePhotoView.swift:双击缩放已有动画](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/SinglePhotoView.swift#L49-L58)

## 具体改动点
- SidebarView.swift
  - 修改 Picked 点击：在现有逻辑前增加对 .single/.fullscreen 的判断，withAnimation 切到 .grid，然后设置 filterFlag。
  - 修改 Rejected 点击：同上。
- ContentView.swift
  - 扩展 onChange(of: viewMode)：新增 .grid 分支
    - currentPhoto = nil
    - selectedPhotos = selectedPhotos ∩ Set(filteredPhotos.map(\.id))

## 验证用例
- 场景 1：单图模式下点击“Picked”→自动切到网格，仅显示已标记 pick 的图片；排序不变；网格选择/双击/导航正常；过渡动画平滑。
- 场景 2：单图模式下点击“Rejected”→行为与“Picked”一致但只显示 reject。
- 场景 3：当前单图不在筛选结果内→切到网格后不再显示该图；信息面板不再显示旧图（因 currentPhoto 清理）。
- 场景 4：之前选中多张但部分不在筛选结果内→切到网格后仅保留筛选结果中的选中项。
- 场景 5：从文件夹管理模式点击“Picked/Rejected”→退出文件夹管理并回到网格，清空 filterFolder；筛选与动画正常。
- 场景 6：切换回“Library → All Photos”→清空 flag 与 folder，回到网格显示全部照片，交互正常。