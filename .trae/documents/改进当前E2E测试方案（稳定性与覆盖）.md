## 问题概况
- UI 测试易碎：大量固定超时与轮询（6–12s、RunLoop busy-wait），依赖文本解析“张数”，遇到本地化或样式变化易失败。[CullerUITests.swift:L29-L41](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L29-L41)、[L72-L94](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L72-L94)
- 本地化耦合：直接点击中文菜单/项（评分、文件名、创建），在英文环境或改文案会失效。[L190-L196](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L190-L196)、[L284-L286](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L284-L286)
- 断言力度不足：仅“存在性/计数变化”，缺少结果正确性验证；如排序只点菜单不校验顺序，Folder Sync在按钮不可见时甚至不做断言。[L183-L196](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L183-L196)、[L254-L260](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift#L254-L260)
- Runner 不是端到端：直接改模型/插入 Photo，跳过 UI/管线（导入、旋转、标记等），更像“数据层冒烟”。[E2ERunner.swift:L110-L116](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L110-L116)、[L133-L139](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L133-L139)
- 排序/筛选的校验偏弱：排序仅校验“元素个数相等”（必然为真），筛选仅过滤数组，无真实查询/索引压力测试。[L122-L126](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L122-L126)、[L117-L121](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L117-L121)
- 持久化未覆盖：Runner用内存库（isStoredInMemoryOnly），无法发现重启/迁移/磁盘权限等问题。[L92-L99](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/E2ERunner.swift#L92-L99)
- 覆盖统计口径偏差：统计脚本优先看日志中的 E2E_CASE，XCUITest 并不打印该标记，容易把“只跑了 Runner”误判为覆盖充分。[check_e2e_feature_coverage.py:L151-L166](file:///Users/bytedance/workspace/ai-demo/culler/script/check_e2e_feature_coverage.py#L151-L166)
- CI/环境限制：UI Runner需要 WindowServer；XCUITest目标在文档中标注不可运行，与代码现状不一致，易造成流水线不可用或混乱。

## 改进方案
- 稳定性
  - 用 XCTNSPredicateExpectation/XCTWaiter 替换自旋轮询；所有等待改为事件驱动。
  - 全量替换中文文案点击为稳定的 Accessibility Identifier；菜单项用稳定 id/shortcut。
- 断言与可观测性
  - 为排序/筛选/标记等增加结果断言：校验首/末元素、具体字段值、持久化后再读验证。
  - UI 截图/快照测试用于关键视图（网格、单图、不可播放提示）。
- 端到端一致性
  - Runner 不再直接改模型：通过同模块的公开 API 或模拟服务层触发流程（导入、同步、旋转）。
  - 为 Runner 输出统一的 E2E_CASE，同时在 XCUITest 中也打印，保证覆盖统计一致。
- 持久化与重启
  - 增加“重启后仍在”的用例：导入—退出—重新启动—断言数据与标记仍在。
  - 将 Runner 的 ModelContainer 改为磁盘存储的临时目录，并清理。
- 覆盖率与CI
  - 覆盖脚本同时扫描 XCUITest 与 Runner 源码标记；CI 两路都跑并合并结果。
  - 在 CI 上配置 macOS + Xcode，跑 xcodebuild test（修复 UITests 可运行性），以及 run_e2e.sh。
- 数据与环境
  - 固化测试资源（确定性图片/坏视频）到仓库或生成策略一致；清理临时目录。

## 执行步骤
1. 统一 UI 标识与等待：替换所有本地化依赖与轮询等待。
2. 强化断言：为排序/筛选/标记/同步新增结果校验与快照。
3. Runner 接入真实流程：通过服务层 API 驱动，不再直接改模型；改用磁盘容器。
4. 覆盖统计与日志：XCUITest 引入 E2E_CASE 打印；脚本合并两路来源。
5. 增加“重启持久化”用例并接入 CI。

## 验证
- 本地：xcodebuild test + run_e2e.sh，确保断言稳定、日志一致。
- CI：两路并行，阈值 90% 以上；失败时输出缺失用例与截图对比。