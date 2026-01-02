## 背景与现状
- 网格视图使用 ScrollView + LazyVGrid(.adaptive) 渲染缩略图，见 [PhotoGridView.swift:L28-L56](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L28-L56)。
- 选中状态与当前项从外部绑定：selectedPhotos、currentPhoto，见 [PhotoGridView.swift:L4-L7](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L4-L7)。
- 进入详情（单图/全屏）由双击或显式切换触发，单图返回按钮在 [SinglePhotoView.swift:L84-L93](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/SinglePhotoView.swift#L84-L93)。
- 目前未实现滚动位置记忆：未使用 ScrollViewReader/scrollTo，也没有读取/设置滚动偏移逻辑。

## 目标与体验
- 用户从网格进入单图详情时记录当前位置。
- 从详情返回网格后：
  - 视图回到原始滚动位置，避免回到顶部。
  - 自动选中当前图片（保持视觉与状态一致）。

## 实现方案（基于锚点）
- 采用“锚点滚动”记忆（以 photo.id 为锚），在模式切换间保持用户位置感知，复杂度低、稳定性好。

### 关键数据
- 在 ContentView 增加状态：`@State var gridScrollAnchor: UUID?`，用于保存需要滚动定位的缩略项 id。
- 设置时机：
  - 进入单图/全屏前或期间，`gridScrollAnchor = currentPhoto?.id`，参考当前切换逻辑 [ContentView.swift:L67-L111](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L67-L111) 与设置 currentPhoto 的位置 [ContentView.swift:L150-L156](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift#L150-L156)。
  - 从详情返回到网格（SinglePhotoView 的 onBack 回调处）保持该值不变，用于回到网格后滚动。

### 网格视图改造
- 用 ScrollViewReader 包裹现有 ScrollView/LazyVGrid，提供 `proxy.scrollTo(anchor, anchor: .center)` 能力。
- 为每个缩略图项设置稳定 id：在 ForEach/缩略图根视图上添加 `.id(photo.id)`，保证 scrollTo 能定位。
- 在网格 `onAppear` 或 `onChange(of: gridScrollAnchor)` 中：
  - 若存在 anchor，则调用 `proxy.scrollTo(anchor, anchor: .center)`。
  - 同步选中：将 selectedPhotos 设为包含该 anchor 对应项，若 currentPhoto 存在则以其为准。
- 参考选中与导航的既有实现：点击/双击处理 [PhotoGridView.swift:L40-L43](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L40-L43)、选择逻辑 [PhotoGridView.swift:L99-L110](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift#L99-L110)。

### 防止回到顶部
- 避免在返回网格时重置数据源或清空选中，保持 state 稳定；在滚动执行前确保照片数组已渲染（可在 `DispatchQueue.main.async` 中触发 scrollTo，避免过早调用）。

## 可选增强（精确偏移）
- 若需精确到像素的滚动偏移（而非锚点）：
  - 在 macOS 使用 NSViewRepresentable 获取内部 NSScrollView 的 `contentView.bounds.origin.y` 存入状态；返回时设置同偏移以还原。
  - 该方案更精细，但开发复杂度高；优先采用锚点方案，后续再迭代。

## 验证方案
- 手动验证：在网格中滚动到中部，双击任意图片进入详情；点击返回：
  - 网格定位到原位置附近且该图片自动高亮选中；
  - 多次往返不会出现跳到顶部。
- 键盘导航联动：在网格中使用方向键移动选中，确保选中项不在视口时自动滚入可见区域（可用同 proxy.scrollTo 处理）。

## 改动文件
- [ContentView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/ContentView.swift)：新增 gridScrollAnchor 状态，设置/传递到网格；在切换模式处维护 anchor。
- [PhotoGridView.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Views/PhotoGridView.swift)：引入 ScrollViewReader，给项 `.id(photo.id)`，在出现/状态变化时执行 scrollTo 并同步选中。
- 如采用精确偏移：新增 NSViewRepresentable 封装（新文件），仅在 macOS 目标下编译。

## 风险与回退
- 如果 photos 列表在返回时发生重排或过滤，锚点可能指向不同位置；可在返回前冻结排序或仅在同数据集下启用定位。
- 若锚点不存在（已删除或过滤），回退到保守行为：不滚动、保持当前选中逻辑。

## 交付项
- 网格模式下完成定位记忆与返回选中，禁止回到顶部。
- 代码遵循现有状态管理与选择模式，变更最小、可维护。