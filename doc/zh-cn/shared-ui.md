# 共享界面基础

MyApps-UI `v0.1.0` 作为子模块放在 `packages/myapps_ui`，相对地址为
`../MyApps-UI.git`。全新克隆后递归初始化子模块。

`lib/app/theme.dart` 保留原有 `AppTheme` 接口和樱花粉品牌色，调用
`myapps_ui`。它重新导出 `AppUiStyle` 和 `NavPlacement`；序列化名称和默认值
保持不变。动态取色仍仅在 Android 上启用。

`lib/shared/utils/adaptive_layout.dart` 导入并重新导出纯函数包
`myapps_adaptive` 的阈值、`canSplitLayout`、`useNavigationRail`、
`columnCapacity` 和 `listRowCount`。参考表格宽度、练习分栏、设置尺寸和
底栏避让保留在应用中，调用接口不变。

本版保留 `shellContentWidth` 原有的宽度预测行为。
实际导航空间测量和公共导航组件属于后续阶段。
资料仍由应用独立管理；数据格式和跨应用身份行为不变。

## 升级

先把共享库提交和标签推送到两个远程，再更新应用子模块指针。
固定到带标签的提交，运行静态分析和完整测试。
共享库函数和行为的权威文档位于其 `doc/en-us/`；
应用只维护品牌配置、接入和业务布局说明。

发布检查：2026-10-04 已查阅 Google Maven 的 ML Kit 分组索引。
`genai-prompt:1.0.0-beta4` 和 `genai-proofreading:1.0.0-beta1` 仍为
列出的最新版本，与应用一致；本次保留这两个版本。
