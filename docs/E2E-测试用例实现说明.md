# E2E 测试用例实现说明

## 测试框架与运行方式
- XCUITest（UI 自动化）
  - 目标与代码： [CullerUITests.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift)
  - 在 Xcode 选择 CullerUITests 运行，或命令行 `xcodebuild test -scheme Culler`
- App 自检 Runner（无头/可见）
  - 运行器与主流程： [E2ERunner.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift)
  - 支持 UI/探针： [UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift)
  - 无头运行：`bash script/run_e2e.sh`（输出 .e2e.log，包含 E2E_START / E2E_RESULT:PASS）
  - 可见 UI：`bash script/run_e2e_ui.sh`（输出 .e2e-ui.log，支持 E2E_UI_PAUSE_SECONDS）
- 覆盖率统计（功能级）：`python3 script/check_e2e_feature_coverage.py`（读取 docs 表与日志/代码标记）

## 通用约定
- 示例数据：启动前重置并播种，确保用例可运行与断言稳定。
- UI 标识：控件设有 Accessibility Identifier；UITestSupport 提供探针与便捷定位。
- 日志标记：Runner 打印 `E2E_CASE:E2E-XX`，并以 `E2E_RESULT:PASS/FAIL` 收尾。
- 环境变量：可配置可见 UI 暂停秒数、示例目录等。

## 用例说明

### E2E-01 启动与网格显示
- 场景与目标：应用启动后展示照片网格，示例数据正确加载。
- 前置条件：示例数据已播种；数据库/索引可用。
- 操作步骤（XCUITest）：启动 App，等待网格视图出现。
- 操作步骤（Runner）：启动流程中重置与播种，检查集合计数与首屏可见。
- 关键断言：网格视图存在，照片数量 > 0。
- 涉及模块：启动流程、数据播种器、网格视图控制器。
- 运行方式：Xcode 运行 CullerUITests 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_01_Launch_ShowsGrid](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L103-L107)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-02 网格→单图→返回
- 场景与目标：从网格进入单图页，再返回网格，导航正确。
- 前置条件：示例数据可展示；存在至少一张照片。
- 操作步骤（XCUITest）：双击缩略图进单图 → 点击返回进入网格。
- 操作步骤（Runner）：确认示例文件存在且元数据完整。
- 关键断言：单图视图出现；返回后网格视图可见。
- 涉及模块：导航控制器、网格/单图视图。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_02_Grid_To_Single_And_Back](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L132-L145)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-03 单图旋转与前后浏览
- 场景与目标：单图页面支持旋转与前后翻阅，确保状态与 UI 一致。
- 前置条件：已播种示例数据并可进入单图；无视频项。
- 操作步骤（XCUITest）：进入单图 → 点击旋转 → 点击下一张 → 点击上一张。
- 操作步骤（Runner）：通过探针记录旋转与索引变化；校验模型状态。
- 关键断言：旋转后渲染角度正确；下一/上一张索引变化；无异常。
- 涉及模块：单图视图控制器、旋转处理器、UITestSupport 探针。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_03_Single_Rotate_Navigate](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L147-L163)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)、[UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift#L1-L50)

### E2E-04 标记工具栏（Pick/评分/色标）
- 场景与目标：在单图页通过工具栏设置挑选、评分与色标，持久化生效。
- 前置条件：单图可进入；模型字段可写。
- 操作步骤（XCUITest）：点击 Pick → 设置 5 星 → 选择红色标签。
- 操作步骤（Runner）：直接修改模型字段 flag/rating/colorLabel 并断言。
- 关键断言：UI 状态与模型字段一致；刷新后仍保留。
- 涉及模块：标记工具栏、模型存储、刷新机制。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_04_Marking_Toolbar_Applies](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L165-L181)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-05 筛选（评分≥3）
- 场景与目标：在网格页设置评分筛选（≥3），计数变化符合预期。
- 前置条件：示例数据包含不同评分。
- 操作步骤（XCUITest）：打开筛选设置评分≥3 → 验证计数变化 → 清除筛选。
- 操作步骤（Runner）：数据侧准备可筛选集合，验证过滤逻辑。
- 关键断言：筛选后集合计数变化；清除后恢复。
- 涉及模块：过滤器、集合数据源。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_05_Filter_Rating_ChangesCount](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L109-L130)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-06 排序（评分/文件名）
- 场景与目标：切换排序方式（评分、文件名），列表顺序符合设定。
- 前置条件：示例数据具备可区分的评分与文件名。
- 操作步骤（XCUITest）：打开排序菜单，切换至“评分”“文件名”。
- 操作步骤（Runner）：验证数据层排序能力与比较器。
- 关键断言：排序键改变时顺序更新正确。
- 涉及模块：排序菜单、数据源排序器。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_06_Sort_Menu_Changes](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L183-L196)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-07 导入
- 场景与目标：通过导入流程添加新照片，计数增加。
- 前置条件：示例目录可用；导入权限与队列正常。
- 操作步骤（XCUITest）：打开导入弹窗 → 生成文件 → 开始导入 → 验证计数增加。
- 操作步骤（Runner）：使用示例目录与模型插入；断言文件存在与索引更新。
- 关键断言：导入完成后集合计数增加；重复导入处理去重或提示。
- 涉及模块：导入弹窗、文件系统接口、模型插入。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_07_Import_AddsPhotos](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L198-L219)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-08 文件夹同步
- 场景与目标：选择示例文件夹进行同步，新增文件被识别并加入集合。
- 前置条件：示例文件夹可访问；FolderSyncService 正常。
- 操作步骤（XCUITest）：从菜单触发 Folder Browser → 执行同步 → 验证计数可能增加。
- 操作步骤（Runner）：调用 FolderSyncService，同步摘要断言新增≥1。
- 关键断言：同步任务完成且新增文件计数符合实际。
- 涉及模块：文件夹选择器、同步服务、索引更新。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_08_FolderSync_AddsNewFile](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L221-L260)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-09 相册与标签管理
- 场景与目标：管理相册与标签，支持创建、关联、删除；计数正确。
- 前置条件：示例数据可供关联；Album/Tag 模型可用。
- 操作步骤（XCUITest）：打开“相册与标签管理” → 创建/删除相册与标签。
- 操作步骤（Runner）：创建 Album/Tag，关联条目并断言数量。
- 关键断言：新增/删除后计数准确；关联关系正确。
- 涉及模块：Album/Tag 管理器、关联映射。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_09_Album_Tag_Management](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L262-L308)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-10 检查器信息
- 场景与目标：在单图页查看信息与文件区域，展示基础元数据。
- 前置条件：条目为图片；元数据可读。
- 操作步骤（XCUITest）：展开信息/文件区域，观察 fileName、大小等。
- 操作步骤（Runner）：断言 fileName 非空与文件大小可读。
- 关键断言：关键字段非空，格式可读；UI 与数据一致。
- 涉及模块：信息面板、文件信息解析器。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_10_Inspector_Shows_Info](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L310-L320)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-11 视频不可播放兜底
- 场景与目标：导入不可播放视频时，显示“当前视频不可播放”的兜底提示。
- 前置条件：生成坏视频样本；导入流程可处理视频。
- 操作步骤（XCUITest）：生成不可播放视频 → 导入 → 进入该条目 → 断言提示出现。
- 操作步骤（Runner）：生成坏视频，AVAsset 检查不可播放并记录失败探针。
- 关键断言：不可播放视频条目进入时显示兜底提示；无崩溃。
- 涉及模块：视频播放器、兜底提示组件、导入流水线。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_11_Video_Fallback_Message](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L322-L346)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

### E2E-12 视频播放基础流程
- 场景与目标：导入可播放视频，进入单图后视频播放器可见且可触发播放。
- 前置条件：有可播放视频样本（使用 CullerUITests/demo/01.mp4）。
- 操作步骤（XCUITest）：导入 demo 视频 → 进入该条目 → 验证播放器与播放按钮 → 点击播放。
- 操作步骤（Runner）：创建 demo 视频条目；校验 AVAsset.isPlayable 为 true。
- 关键断言：播放器容器存在；播放按钮可见且可点击；视频资源可播放。
- 涉及模块：视频播放器、导入流程、视频识别。
- 运行方式：Xcode 或 `run_e2e.sh`。
- 代码参考：
  - XCUITest: [test_E2E_12_Video_Playback_ShowsControls](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L348-L395)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)

## 维护建议
- 新增用例时按本模板新增小节，并在 Runner/XCUITest 中增加对应标记与断言。
- UI 标识或脚本参数变更时，同步更新“运行方式”“代码参考”与覆盖率脚本元数据。
