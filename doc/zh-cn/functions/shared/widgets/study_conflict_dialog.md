# lib/shared/widgets/study_conflict_dialog.dart

当同步发现同一项在两台设备上都被学习过时，为每条冲突记录显示一次的对话框。见
[../../../sync.md](../../../sync.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 当同步发现一条记录在两台设备上都被修改时，让用户选择保留哪一个。 |
| `StudyConflictDialog` | 构造函数 | B | 创建学习冲突对话框实例。 |
| `StudyConflictDialog._formatTime` | 静态方法 | B | 按设备时区格式化 UTC 时间戳。 |
| `StudyConflictDialog._version` | 方法 | B | 把一个版本的信息渲染为带标题的区块。 |
| `StudyConflictDialog._historyVersion` | 方法 | B | 显示被记住句子冲突的一侧。 |
| `StudyConflictDialog._examVersion` | 方法 | B | 显示考试作答冲突的一侧。 |
| `StudyConflictDialog._profileVersion` | 方法 | B | 显示学习者档案冲突的一侧。 |
| `StudyConflictDialog.build` | 方法 | B | 构建当前控件子树。 |
| `showStudyConflictDialog` | 顶层函数 | A | 展示一条冲突并等待用户选择。 |

### `showStudyConflictDialog`

- **Purpose:** 展示一条冲突并等待用户选择。
- **Inputs:** `context`；`conflict` —— 合并报告的记录对；`label` —— 来自
  [`resolveStudyItemLabel`](../../features/content/services/study_item_labels.md)。
- **Returns:** `Future<StudyRecord?>` —— 保留的记录；用户以系统返回键关闭对话框时为 null。
- **Side effects:** 打开模态路由。
- **Algorithm:** 使用 `barrierDismissible: false` 的 `showDialog`；文本按钮弹出本地记录，实心按钮弹出
  远程记录。
- **Usage:** 由 WebDAV 页面在 `pending.allConflicts` 上循环调用。
- **Notes:** 没有取消动作，遮罩也不可点击，因为解决冲突是全有或全无的：调用方把 null 当作“中止整次同步”，
  绝不当作“保留本地”。每个区块显示按本地时区的修改时间、正确与错误次数、连续答对次数、推导出的阶段，以及
  上次复习时间。

**四种区块，因为并非每条记录都有计数器。** `_version` 依据 `record.kind` 分派：

- 普通条目显示本地时区的修改时间、答对与答错次数、连续正确数、推导出的阶段，以及最后一次复习的时间。
- **学习者档案**（`profile:me`）改为显示目标级别、每日上限与连续天数。「答对 0 · 答错 0，阶段：全新」并不是对目标级别的描述，而学习者读不懂的冲突就是他们无法解决的冲突。
- **被记住的句子**（`lab:` 或 `writing:`，来自 `v0.3.2`）显示时间戳与完整文本。文本*就是*那条记录，截断它会把唯一能区分两个版本的东西藏起来。
- **考试作答**（`exam:`）显示级别与模式、得分，以及卷子是什么时候作答的。一次作答*确实*有计数器字段——写它们是为了让旧版构建的对话框说出真话——但它们不是区分同一次作答两个版本的东西。真正区分它们的是这份卷子：哪个级别、练习还是计时、什么时候作答的，以及得了多少分。这里刻意**不**重复计数器，因为「答对 48 · 答错 19」与「48 / 67」并列，是同一个事实换两种形状说了两遍。

每种区块都通过各自模型的 `fromRecord` 读取载荷，因此由更新的构建写入、带有本构建无法显示字段的记录，仍能把它能显示的部分渲染出来。

