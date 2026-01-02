## 目标
- 删除仓库中所有与“截图”或“输入交互”相关的端到端（E2E）测试与配套脚本、配置。

## 范围
- iOS/macOS Xcode UITests 测试代码与目标。
- 任何生成截图（XCUIScreen/XTAttachment）或执行输入交互（click/typeKey/tap/typeText）的测试逻辑。
- 触发或导出 UITests 结果的脚本与 Xcode Scheme/Target 配置。

## 删除项与改动
- 删除测试代码（文件级）：
  - 删除 UITests 主文件：[CullerUITests.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift)。
  - 删除测试辅助文件（若仅用于 E2E）：[UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift)。
- 删除测试脚本：
  - 删除运行与导出截图脚本：[e2e.sh](file:///Users/bytedance/workspace/ai-demo/culler/scripts/e2e.sh)。
- 清理 Xcode 配置：
  - 从 Scheme 中移除 UITests 测试目标：[Culler.xcscheme](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler.xcodeproj/xcshareddata/xcschemes/Culler.xcscheme) 的 TestAction TestableReference（CullerUITests）。
  - 从工程文件中移除 UITests 目标与文件引用：[project.pbxproj](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler.xcodeproj/project.pbxproj) 中的 com.apple.product-type.bundle.ui-testing、CullerUITests.xctest 及其源文件条目。
- 若选择保留文件但禁用能力（备选方案）：
  - 在 [CullerUITests.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/CullerUITests/CullerUITests.swift) 内删除/置空截图函数（如 capture(_:)）与所有 click()/typeKey()/tap()/typeText() 调用。
  - 在 [UITestSupport.swift](file:///Users/bytedance/workspace/ai-demo/culler/Culler/Culler/Testing/UITestSupport.swift) 内移除 -ui-testing 相关逻辑（如不再需要种数据）。

## 验证
- 运行项目构建，确保无 UITests 目标或脚本引起的引用错误。
- 运行单元测试（若存在），确保删除 E2E 后测试仍通过。
- 全局检索确认不再存在截图 API（XCUIScreen.main.screenshot、XCTAttachment）与输入 API（click/typeKey/tap/typeText）。

## 风险与注意
- 若应用在运行时依赖 UITestSupport 的数据种子，需要评估是否保留其中非测试必需的逻辑。
- 删除 Scheme/Target 需保持工程稳定；若团队存在共享 Scheme，注意同步。

## 交付
- 提交删除与清理变更，包含：源文件移除、脚本移除、Xcode 配置更新。
- 提供一次验证记录（构建与测试结果）及最终确认清单。