# lib/features/ai/widgets/ai_source_controls.dart

## AI 来源与 WebDAV 隐私

MyApps-AI v0.6.0 显式拆分运行时、平台、模型、本地 UI、来源和 llama.cpp 包。设置使用统一分区骨架。全局来源选择保存在设备本地（`aiSourceSelection`），默认系统 AI；MyNihongo 没有在线来源，AI 始终留在设备上。共享的 `AiSourceRouter`（由 `createAiSourceRouter` 创建，作为 `MethodChannelGenAiBackend.sourceBackend` 持有）显示易读的模型名称，如 `Qwen: Qwen3.5 0.8B (Q4_K_M)`，允许重命名模型，仅在用户开启且设备已验证时让本地模型使用 GPU（GPU 失败会回退到 CPU 并被记住），并且只有在强制警告之后才接受自定义的 Hugging Face GGUF 模型。设备本地键 `aiComputePreference`、`aiGpuFailures`、`aiCustomModels` 与 `aiModelAliases` 从不同步，也不进入备份。Qwen3.5 0.8B/2B Q4_K_M 与 Gemma 4 E2B Q4_0 默认在 CPU 上运行。下载仅由明确操作触发，使用固定地址与 SHA-256，保存在 `ai_models/`，不进入数据模块、同步、备份或 ZIP。模型租约避免使用中移除文件。切换来源取消旧任务并释放模型资源。技术详情仍位于调试模式设置之后，是对每个包含的后端（`router.diagnostics()`）的完整、可复制的报告。MyNihongo 的系统校对保持独立，始终使用系统 AI。

WebDAV 第 1 版提醒必须在每个设备上确认后，才能测试连接、手动/强制同步或后台同步。记录保存在设备本地 storage_config.json。已有配置保持不变，同步暂停时 WebDAV 页面显示查看提醒横幅。拒绝不保存配置、不发出请求。JSON/图片没有应用层加密；HTTPS 加密传输，HTTP 不加密。线格式、锁和冲突策略保持不变。

## Declarations

| Declaration | Purpose |
|---|---|
| `const AiSourceControls({` | 绑定路由与选择回调。 |
| `Widget build(BuildContext context) {` | 渲染共享的 `MyAppsAiSourceSection`（来源选择、本地模型入口、GPU 开关；无在线入口）。 |
| `Future<void> openAiLocalModels(BuildContext, AiSourceRouter, String?)` | 打开本地模型页，含重命名菜单和“添加自定义模型”入口（`MyAppsAddCustomModelPage`，Hugging Face GGUF，强制警告）。 |
| `MyAppsLocalModelLabels _modelLabels(AppLocalizations, AiSourceRouter)` | 构建模型列表标签；名称来自路由（易读名称或别名）。 |
| `class _ModelMenu extends StatelessWidget` | 每个模型的菜单：重命名；自定义模型还可从列表移除。 |
| `Widget build(BuildContext context) {`（`_ModelMenu`） | 构建弹出菜单。 |
| `class _AliasDialog extends StatefulWidget` | 持有自身文本控制器的重命名对话框。 |
| `Widget build(BuildContext context) {`（`_AliasDialogState`） | 构建对话框；保存时返回输入的别名。 |

`modelDisplayName` 已移除：模型名称来自 `AiSourceRouter.sourceName`（例如 `Qwen: Qwen3.5 0.8B (Q4_K_M)`）。
