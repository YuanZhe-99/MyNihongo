# lib/main.dart

应用入口点。它初始化 Flutter 绑定，触发每日一次的自动备份检查（用户启用自动备份之前是空操作），启动自动同步生命周期观察者（配置 WebDAV 之前是空操作），并在 `ProviderScope` 中运行 `MyNihongoApp`，外层包着仅在调试构建中启用的 `DevicePreview`。见 [../architecture.md](../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `main` | 顶层函数 | B | 初始化启动服务并启动应用入口点。 |
