# WebDAV 同步

P3 公共资料实现与适配见 [shared-ui.md](shared-ui.md)，格式和模块顺序保持不变。

同步引擎不在此仓库。`WebDavSyncEngine`、WebDAV 客户端、上传锁、三方合并和自动同步调度器位于 `packages/myapps_data` 下的共享 `myapps_data` 包中，文档在 `packages/myapps_data/doc/en-us/`——从它的 `architecture.md` 和 `invariants.md` 开始。本页只记录 MyNihongo!!!!! 接入该引擎的部分，以及用户看到的东西。

## 同步什么

两个数据模块，在 `lib/app/data_modules.dart` 中声明一次。顺序有意义：进度在前，个人资料（0.6.0）追加在最后。

| 本地与远程文件 | 备份模块 id | 默认远程路径 |
|---|---|---|
| `nihongo_progress.json` | `progress` | `/MyNihongo` |
| `profile.json`（0.6.0） | `profile` | `/MyNihongo` |

别无其他。内容目录随应用发布，设备偏好留在 `storage_config.json`。仅有的图像是个人资料头像：个人资料模块的 `referencedImages` 钩子返回头像的基名，因此引擎的图像阶段（添加式，按文件名，位于 `images/` 下）会上传和下载它。见[个人资料文件](#个人资料文件)。

## 一次同步如何运行

工作由引擎完成：获取远程 `.lock`（60 秒 TTL，20 秒心跳），下载远程文件，与本地文件和 `.sync_base/` 中的基线快照比较，合并，本地写入，上传，保存新基线，释放锁。两条路径与本应用相关：

- **原始快速路径。** 如果本地和远程字符串完全相同，就不合并也不上传。这就是 `NihongoStorage.save()` 与引擎都写两空格美化 JSON 的原因；格式差异会让每次同步永远重新上传一个未改动的文件。
- **模块合并。** 字符串不同时，引擎调用 `mergeProgressModule`，它包装 `mergeProgressData`（`lib/shared/services/sync_merge.dart`）：把本地、远程和基线解析为 `ProgressData`，运行包里以 `id` 为键、按 `modifiedAt` 比较的通用 `mergeRecords<StudyRecord>`，然后把两侧的未知 JSON 重新附上。只在一侧改动的记录取那一侧；一侧删除、另一侧未动的记录被删除；自基线以来**两侧**都改动的记录是**冲突**。

## 冲突呈现给用户

冲突绝不静默解决——`autoResolve` 在每个调用点都是 false，这是与兄弟应用共享的不变量。引擎返回挂起结果；`WebDAVService` 把它包装成携带有类型 `ProgressMergeResult` 的 `PendingSync`，因此冲突对话框（`lib/shared/widgets/study_conflict_dialog.dart`）可以展示每条记录的两个副本——通过目录把 id 解析为它命名的假名、词条或句型，两侧各附计数器和 `modifiedAt`——并让用户逐记录保留本地或远程副本。关闭对话框即中止解决。`finalizePendingSync` 重新下载远程文件，并在新锁下上传解决后的数据；基线快照只在该上传成功后保存。

没有决定的冲突回落到本地记录（`ProgressMergeResult.buildResolved`），与兄弟应用使用的回落相同。

## 自动同步

`AutoSyncService` 是包内 `AutoSyncScheduler` 的门面（facade）：启动时、恢复时、每 15 分钟、以及最后一次保存后 30 秒同步（`NihongoStorage.save()` 调用 `notifySaved()`）。它的两个应用钩子都运行每日自动备份检查，因此跨过午夜仍开着的设备依然会得到备份。后台同步同样绝不自动解决；后台发现的冲突会设置 `hasPendingConflicts`，由设置 UI 呈现。

## 强制操作

`forceUpload` 用本地数据覆盖远程；`forceDownload` 用远程覆盖本地数据。两者都在锁下运行，都会丢掉另一侧自上次同步以来的更改，因此 UI 在两者之前都会确认。写入了数据的备份恢复之后，应用禁用自动同步并提供强制上传，使恢复的旧数据不会把删除传播到其他设备（系列不变量 I5）。

## 在 iPhone 和 Mac 上：本地网络访问

Apple 会在应用访问本地网络上的服务器之前询问用户（iOS 14 及以上，macOS 15 及以上）。根据 Apple 的文档（TN3179），这一询问也涵盖 BSD 套接字，而 WebDAV 客户端底层的 `dart:io` 用的正是它；并且对本地地址走 HTTPS 与走 HTTP 同样会询问。`Info.plist` 带有 `NSLocalNetworkUsageDescription`，说明应用只连接学习者配置的那台 WebDAV 服务器。

第一次连接局域网服务器会弹出系统提示，而 `dart:io` 无法等待用户作答，因此提示还在屏幕上时，第一次连接测试或同步可能失败。所以在 iPhone 和 Mac 上，**测试连接**失败时会提示去系统设置中允许本地网络访问后重试（`platformAsksForLocalNetwork`）；在其他平台上仍是「连接失败」。

App Transport Security——Apple 的另一条网络规则——并不适用：它管辖的是 Apple 的 URL Loading System，而这个客户端从不经过它。见 [`platform-notes.md`](platform-notes.md)。以上情况都未曾在设备上观察到；这里描述的 Apple 行为出自 Apple 的文档。

## 个人资料文件

自 0.6.0 起，注册表包含第二个模块 `profile.json`——用户的名称和头像（schema 见 [`data-formats.md`](data-formats.md#profilejson)，功能见 [`features/profile.md`](features/profile.md)）。它在进度模块之后走同一套引擎步骤，处在同一个 `.lock` 之下，并有自己的 `.sync_base/profile.json`。

- **合并从不产生冲突，也不需要基线。**每个字段按各自的时间戳独立地后写者胜：名称看 `displayNameUpdatedAt`，头像看 `avatarUpdatedAt`。远程时间戳严格更晚才胜出，相同时保留本地，从未设置该字段的一侧总是输给设置过的一侧。因此一台设备改了名称、另一台设备改了头像，两者都会保留。未知键取并集，本地优先，并保留较高的 `version`。它从不显示冲突对话框。
- **移除是显式的。**清除头像会写入带新时间戳的 `"avatar": null`（清除名称则写入 `"displayName": null`），因此移除与其他编辑一样赢得合并，而不会被误认为从未设置的字段。
- **头像文件名唯一。**头像是 `images/` 中的普通文件，经由引擎的添加式图像阶段传输（该模块的 `referencedImages` 返回它的基名）。图像同步从不覆盖另一侧已存在的文件，也从不删除，因此每个新头像都使用全新的 `images/avatar_<uuid>.jpg` 名称；复用同一个名称会让其他设备一直显示旧图。被替换的头像只在做出更改的那台设备上删除：**旧头像会留在 WebDAV 服务器和其他设备上**（已知限制）。
- **旧版本忽略它。**引擎只请求它已注册的文件名，也从不列出远程根目录，因此 0.6.0 之前的构建从不获取 `profile.json`；头像文件无害地躺在 `images/` 中。
- **开销。**每次同步多一次 `GET profile.json`（从未设置个人资料的片库会得到 404）；已录制的 WebDAV 记录已重新录制，只多了这一个请求。
- 每次保存个人资料都会调用 `AutoSyncService.notifySaved`，因此防抖同步会在编辑后不久运行；同步或恢复重写本地数据后，个人资料 provider 会重新加载。

## 文件

- `webdav_config.json` — 服务器 URL、凭据、远程路径、自动同步标志。永不同步。
- `.sync_base/nihongo_progress.json` — 基线快照。更改存储路径时把它留在原地，会让下次同步复活其他设备已删除的记录，这正是 `NihongoStorage.setStoragePath` 迁移整个文件夹的原因。
- `.sync_base/profile.json` — 个人资料模块的基线快照（0.6.0）。
- `.sync_base/upload_lock.json` — 检测中途中断的上传。

## AI 来源与 WebDAV 隐私

MyApps-AI v0.6.0 显式拆分运行时、平台、模型、本地 UI、来源和 llama.cpp 包。设置使用统一分区骨架。全局来源选择保存在设备本地（`aiSourceSelection`），默认系统 AI；MyNihongo 没有在线来源，AI 始终留在设备上。共享的 `AiSourceRouter`（由 `createAiSourceRouter` 创建，作为 `MethodChannelGenAiBackend.sourceBackend` 持有）显示易读的模型名称，如 `Qwen: Qwen3.5 0.8B (Q4_K_M)`，允许重命名模型，仅在用户开启且设备已验证时让本地模型使用 GPU（GPU 失败会回退到 CPU 并被记住），并且只有在强制警告之后才接受自定义的 Hugging Face GGUF 模型。设备本地键 `aiComputePreference`、`aiGpuFailures`、`aiCustomModels` 与 `aiModelAliases` 从不同步，也不进入备份。Qwen3.5 0.8B/2B Q4_K_M 与 Gemma 4 E2B Q4_0 默认在 CPU 上运行。下载仅由明确操作触发，使用固定地址与 SHA-256，保存在 `ai_models/`，不进入数据模块、同步、备份或 ZIP。模型租约避免使用中移除文件。切换来源取消旧任务并释放模型资源。技术详情仍位于调试模式设置之后，是对每个包含的后端（`router.diagnostics()`）的完整、可复制的报告。MyNihongo 的系统校对保持独立，始终使用系统 AI。

WebDAV 第 1 版提醒必须在每个设备上确认后，才能测试连接、手动/强制同步或后台同步。记录保存在设备本地 storage_config.json。已有配置保持不变，同步暂停时 WebDAV 页面显示查看提醒横幅。拒绝不保存配置、不发出请求。JSON/图片没有应用层加密；HTTPS 加密传输，HTTP 不加密。线格式、锁和冲突策略保持不变。
