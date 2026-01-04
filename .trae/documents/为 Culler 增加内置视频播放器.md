## 要求更新
- 快捷键策略：除空格外，所有视频相关快捷键仅在“正在播放”时生效；暂停或未播放时，不影响/不覆盖现有全局或照片模式快捷键。

## 快捷键映射
- 空格：播放/暂停（始终可用，只要视频项处于激活）。
- 仅在播放中生效的键：
  - 左/右：后退/前进 5s；Shift+左/右：后退/前进 10s。
  - J/K/L：后退 10s / 暂停 / 前进 10s（可开关）。
  - 上/下：音量 +/−；M：静音。
  - F：全屏；Esc：退出全屏。
- 暂停时：以上除空格外全部不注册/不响应，避免与评分/标记等快捷键冲突。

## 实现策略（作用域 + 动态注册）
1. 作用域：扩展 KeyboardShortcutManager 支持 .video 作用域与优先级路由；VideoPlayerView 激活时进入 .video 作用域。
2. 动态注册：根据 player.timeControlStatus：
   - .playing：注册播放专属键（除空格外的所有上列键）。
   - .paused/.waitingToPlayAtSpecifiedRate：仅注册空格键；其他键全部注销，恢复全局快捷键行为。
3. 事件路由：VideoPlayerView 管理注册生命周期（onAppear 注册；onDisappear 注销）；状态切换时即时更新注册集合。
4. 手势：双击用于播放/暂停（与键盘规则一致，不在暂停时激活其他键）。

## 播放器集成
- SinglePhotoView 中，当 Photo.isVideo 为 true 显示 VideoPlayerView；使用 AVKit.VideoPlayer 与自定义覆盖层控件。
- 复用 Photo.fileURL 与安全作用域访问；视图切换时暂停并释放资源。

## 错误与兼容
- item.status 失败或 asset 不可播放：显示“当前视频不可播放”，提供外部打开选项。

## 设置项
- 开关 J/K/L；箭头跳转步长；双击行为；全部不影响“仅在播放时生效”的规则。

## 测试
- 验证空格始终可用；其他键仅在播放中响应。
- 暂停时评分/标记等快捷键可正常使用；播放时这些快捷键不被触发。
- 播放控制、错误提示、资源释放按预期工作。

## 交付
- 新增：Views/VideoPlayerView.swift。
- 修改：SinglePhotoView.swift（视频条件渲染与手势/键盘接入）。
- 修改：KeyboardShortcutManager.swift（作用域与动态注册）。
- 文档：更新“视频播放与快捷键”。