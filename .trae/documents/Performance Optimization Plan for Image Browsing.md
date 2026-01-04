我已定位到图片浏览卡顿和加载慢的核心原因，并制定了详细的优化方案。

### **核心问题分析**
1.  **滚动卡顿 (Freeze during scrolling)**:
    *   **`ThumbnailService` 串行阻塞**: 当前服务是 `actor`，但内部使用了同步的图片解码 API (`CGImageSource`)。这意味着所有缩略图请求都在同一个队列中排队，一张大图解码会阻塞后续所有图片的加载。
    *   **主线程频繁调度**: `AsyncThumbnailView` 对每个单元格（即使是缓存命中的）都启动异步任务并多次切换回主线程，在快速滚动时造成主线程压力。
2.  **加载变慢 (Slow loading)**:
    *   **无效的缓存等待**: 即使图片已经在内存缓存中，代码依然通过异步方式获取，导致界面出现不必要的“加载中”占位符，视觉体验不流畅。
3.  **模型计算开销**:
    *   **`isVideo` 属性**: 每次渲染单元格都会创建新的 `URL` 对象并查询系统文件类型 (UTI)，这在高频刷新时（如滚动）会消耗大量 CPU。

### **优化方案**

#### **1. 重构 `ThumbnailService` 实现高并发 (高优先级)**
*   **解除 Actor 限制**: 将 `ThumbnailService` 从 `actor` 改为线程安全的 `final class`。`NSCache` 本身是线程安全的，这样可以允许多个线程同时读取缓存，而不需要排队。
*   **异步非阻塞生成**: 将耗时的图片生成代码移入 `Task.detached`，利用系统的并发能力同时解码多张图片，彻底解决“一张图卡死整个队列”的问题。
*   **提供同步接口**: 新增 `cachedThumbnail(for:size:)` 方法，允许视图层直接同步拿到缓存图片。

#### **2. 优化 `AsyncThumbnailView` 视图层 (高优先级)**
*   **同步缓存命中**: 修改加载逻辑，优先调用同步缓存接口。
    *   **如果有缓存**: 立即显示图片，**不显示 Loading 动画，不进行淡入淡出**，实现如原生相册般的丝滑滚动。
    *   **无缓存**: 才启动异步任务进行加载。

#### **3. 优化 `Photo` 数据模型 (中优先级)**
*   **轻量化 `isVideo`**: 重写该属性，直接通过文件路径后缀（字符串比较）来判断是否为视频，避免昂贵的 URL 和 UTI 对象创建。

### **修改文件列表**
1.  `Culler/Culler/Services/ThumbnailService.swift`
2.  `Culler/Culler/Views/PhotoGridView.swift`
3.  `Culler/Culler/Models/Photo.swift`
