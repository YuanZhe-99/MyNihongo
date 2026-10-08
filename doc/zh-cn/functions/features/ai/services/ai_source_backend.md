# lib/features/ai/services/ai_source_backend.dart

## AI 来源与 WebDAV 隐私

MyApps-AI v0.6.0 显式拆分运行时、平台、模型、本地 UI、来源和 llama.cpp 包。设置使用统一分区骨架。全局来源选择保存在设备本地（`aiSourceSelection`），默认系统 AI；MyNihongo 没有在线来源，AI 始终留在设备上。共享的 `AiSourceRouter`（由 `createAiSourceRouter` 创建，作为 `MethodChannelGenAiBackend.sourceBackend` 持有）显示易读的模型名称，如 `Qwen: Qwen3.5 0.8B (Q4_K_M)`，允许重命名模型，仅在用户开启且设备已验证时让本地模型使用 GPU（GPU 失败会回退到 CPU 并被记住），并且只有在强制警告之后才接受自定义的 Hugging Face GGUF 模型。设备本地键 `aiComputePreference`、`aiGpuFailures`、`aiCustomModels` 与 `aiModelAliases` 从不同步，也不进入备份。Qwen3.5 0.8B/2B Q4_K_M 与 Gemma 4 E2B Q4_0 默认在 CPU 上运行。下载仅由明确操作触发，使用固定地址与 SHA-256，保存在 `ai_models/`，不进入数据模块、同步、备份或 ZIP。模型租约避免使用中移除文件。切换来源取消旧任务并释放模型资源。技术详情仍位于调试模式设置之后，是对每个包含的后端（`router.diagnostics()`）的完整、可复制的报告。MyNihongo 的系统校对保持独立，始终使用系统 AI。

WebDAV 第 1 版提醒必须在每个设备上确认后，才能测试连接、手动/强制同步或后台同步。记录保存在设备本地 storage_config.json。已有配置保持不变，同步暂停时 WebDAV 页面显示查看提醒横幅。拒绝不保存配置、不发出请求。JSON/图片没有应用层加密；HTTPS 加密传输，HTTP 不加密。线格式、锁和冲突策略保持不变。

本文件取代原先应用自有的 `AiSourceBackend` 类：路由、本地模型管理、GPU 偏好、自定义模型、别名和诊断现在都来自 `myapps_ai_sources` 中的 `AiSourceRouter`，本文件重新导出 `AiSourceRouter`。路由只会把 `aiComputePreference`、`aiGpuFailures`、`aiCustomModels` 与 `aiModelAliases` 写入本设备的 `storage_config.json`。

## Declarations

| Declaration | Purpose |
|---|---|
| `AiSourceRouter createAiSourceRouter({StorageAdapter? storage, CapabilityGenAiBackend? system})` | 基于 MyNihongo 存储创建应用的 AI 来源路由。输入：测试用的可选存储与系统后端。返回：共享的 `AiSourceRouter`。在后台读取应用版本用于技术详情；模型文件位于 `<应用目录>/ai_models`，不进入同步和备份；没有在线来源。 |
