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
