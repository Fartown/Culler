## 目标
- 在 docs 目录新增一份面向开发与测试的说明文档，系统化描述当前每个 E2E 测试用例的实现方案（覆盖 XCUITest 与 App 自检 Runner 两条路径），包括前置条件、关键步骤、断言、涉及模块与运行方式。

## 输出文件
- 新增文件：docs/E2E-测试用例实现说明.md
- 内容以用例为单位，提供清晰的可执行说明与代码参考链接。

## 文档结构
1. 文档概览（框架与运行方式）
   - 测试框架：XCUITest（CullerUITests）与 App 自检 Runner（E2ERunner）
   - 运行脚本与日志标记（run_e2e.sh、run_e2e_ui.sh、E2E_START/E2E_RESULT）
2. 通用约定
   - 示例数据播种与重置策略
   - UI 可访问标识（Accessibility Identifier）与 UITestSupport 的探针约定
   - 覆盖率统计脚本的用法与元数据来源
3. 用例说明（11 个用例，每个独立小节）
   - 用例编号与名称（E2E-01 … E2E-11）
   - 场景与目标
   - 前置条件
   - 操作步骤（XCUITest 与 Runner 两条实现思路）
   - 关键断言与验证点
   - 涉及模块/关键 API
   - 运行方式与脚本参数
   - 注意事项（稳定性、数据依赖、环境变量）
   - 代码参考（文件与行号链接）

## 信息来源
- XCUITest： [CullerUITests.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift)
- Runner： [E2ERunner.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift)
- UI/探针： [UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift)
- 文档： [功能说明与E2E.md](file:///Users/bytedance/workspace/ai-demo/culler/docs/功能说明与E2E.md)
- 脚本： [run_e2e.sh](file:///Users/bytedance/workspace/ai-demo/culler/script/run_e2e.sh)、[run_e2e_ui.sh](file:///Users/bytedance/workspace/ai-demo/culler/script/run_e2e_ui.sh)
- 覆盖： [check_e2e_feature_coverage.py](file:///Users/bytedance/workspace/ai-demo/culler/script/check_e2e_feature_coverage.py)

## 用例清单（拟写入文档）
- E2E-01 启动与网格显示
  - XCUITest: [test_E2E_01_Launch_ShowsGrid](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L103-L107)
  - Runner: 启动与播种，断言照片存在
- E2E-02 网格→单图→返回
  - XCUITest: [test_E2E_02_Grid_To_Single_And_Back](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L132-L145)
  - Runner: 文件存在与可展示
- E2E-03 单图旋转与前后浏览
  - XCUITest: [test_E2E_03_Single_Rotate_Navigate](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L147-L163)
  - Runner: 探针与状态记录（见 UITestSupport）
- E2E-04 标记工具栏（Pick/评分/色标）
  - XCUITest: [test_E2E_04_Marking_Toolbar_Applies](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L165-L181)
  - Runner: 修改模型字段并断言
- E2E-05 筛选（评分>=3）
  - XCUITest: [test_E2E_05_Filter_Rating_ChangesCount](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L109-L130)
  - Runner: 依赖可筛选数据集
- E2E-06 排序（评分/文件名）
  - XCUITest: [test_E2E_06_Sort_Menu_Changes](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L183-L196)
  - Runner: 数据层排序能力
- E2E-07 导入
  - XCUITest: [test_E2E_07_Import_AddsPhotos](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L198-L219)
  - Runner: 示例目录与模型插入
- E2E-08 文件夹同步
  - XCUITest: [test_E2E_08_FolderSync_AddsNewFile](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L221-L260)
  - Runner: FolderSyncService 同步摘要断言
- E2E-09 相册与标签管理
  - XCUITest: [test_E2E_09_Album_Tag_Management](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L262-L308)
  - Runner: 创建并关联、计数断言
- E2E-10 检查器信息
  - XCUITest: [test_E2E_10_Inspector_Shows_Info](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L310-L320)
  - Runner: 文件名与大小可读断言
- E2E-11 视频不可播放兜底
  - XCUITest: [test_E2E_11_Video_Fallback_Message](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L322-L346)
  - Runner: 坏视频生成与 AVAsset 不可播放检查

## 示例节格式（写入文档的模板）
### E2E-03 单图旋转与前后浏览
- 场景与目标：单图页面支持旋转与前后翻阅，确保状态与 UI 一致。
- 前置条件：已播种示例数据并可进入单图；无视频项。
- 操作步骤（XCUITest）：进入单图 → 点击旋转 → 点击下一张 → 点击上一张。
- 操作步骤（Runner）：执行探针记录旋转与索引变化；校验模型状态。
- 关键断言：旋转后渲染角度正确；下一/上一张索引变化；无异常；日志包含 E2E_CASE:E2E-03。
- 涉及模块：单图视图控制器、旋转处理器、UITestSupport 探针。
- 运行方式：Xcode 运行 CullerUITests 或 bash script/run_e2e.sh。
- 代码参考：
  - XCUITest: [CullerUITests.swift:L147-L163](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L147-L163)
  - Runner: [E2ERunner.swift:run](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L80-L201)、[UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift#L1-L50)

## 执行步骤
1. 逐个阅读并提取 11 个用例的实现细节（前置、步骤、断言、涉及模块、运行与日志）。
2. 按模板撰写每个用例的小节，补充必要的代码链接与脚本参数。
3. 在 docs 目录新增 E2E-测试用例实现说明.md 并填入完整内容。
4. 在 docs/功能说明与E2E.md 中添加交叉引用（如需），保持两文档一致性。

## 验证方式
- 本地运行 XCUITest 与 Runner 脚本，核对各断言与日志标记与文档一致。
- 使用覆盖率脚本 check_e2e_feature_coverage.py 验证文档列出的用例和标记对应关系。

## 后续维护
- 新增用例时，按同一模板更新文档与覆盖率脚本元数据。
- 若 UI 标识或脚本参数变更，同步更新对应节的“运行方式”和“代码参考”。