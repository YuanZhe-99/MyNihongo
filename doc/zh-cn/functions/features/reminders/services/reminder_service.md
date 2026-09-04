# lib/features/reminders/services/reminder_service.dart

让每天那一条提醒，指向学习者真正在等着的东西。与语音和 AI 服务一样是单例，理由也相同：设备上只有一份通知排程，两个持有者会打架。

使用方：`main.dart`、`app_settings.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `ReminderService` | 类 | B | 持有设备的提醒排程。 |
| `ReminderService.instance` | 字段 | B | 全应用实例。 |
| `ReminderService.setInstanceForTest` | 方法 | B | 在测试中替换它。 |
| `ReminderService._backendForPlatform` | 方法 | B | 选出该平台需要的后端。 |
| `desktopTick` | 常量 | B | 桌面路径多久看一次表。 |
| [`ReminderService.init`](#init) | 方法 | A | 准备平台，不请求任何东西。 |
| `ReminderService.requestPermission` | 方法 | B | 请求通知权限。 |
| [`ReminderService.reschedule`](#reschedule) | 方法 | A | 重算计划并交给平台。 |
| [`ReminderService._startTicking`](#tick) | 方法 | A | 在没人会代劳的地方看表。 |
| `ReminderService.isTicking` | getter | B | 桌面定时器是否在跑。 |
| `ReminderService.dispose` | 方法 | B | 停掉定时器。 |

## 文档

### `Future<void> init()` <a id="init"></a>

- **种类：** 方法
- **用途：** 准备平台，且不向学习者请求任何东西。
- **输入：** 无。
- **返回：** 后端就绪时完成的 future。
- **副作用：** 初始化插件与时区数据库。
- **算法：** 委托给后端，由它加载时区数据库并在关闭全部权限请求的前提下初始化插件。
- **用法：** `main.dart`，在启动时不 await 地调用。
- **说明：** **它绝不能请求权限**，并且有一条测试断言它发起的请求数为零。从未打开过提醒的设备的主人，不会被请求任何东西；请求住在设置的开关里。M2.4 曾发布过一个一打开设置就请求麦克风的版本，而这是同一个错误，只差一行。

### `Future<void> reschedule(AppLocalizations l10n, {DateTime? now})` <a id="reschedule"></a>

- **种类：** 方法
- **用途：** 重算计划并交给平台。
- **输入：** 用于措辞的 `l10n`；供测试用的 `now`。
- **返回：** 排程被替换后完成的 future。
- **副作用：** 读取偏好、进度文件与路径；排程或取消。
- **算法：** 提醒关闭时取消并返回；否则读取时间、档案与该级别的路径，规划一周，并替换排程。
- **用法：** 每一个可能改变提醒内容的设置项都会调用它。
- **说明：** 它自己去读偏好，而不是被告知，因此每个调用方都是同样的一行。提醒关闭时它执行取消而不是什么都不做，这正是关掉开关能立即生效、而不是一周后才生效的原因。

### `void _startTicking(List<ScheduledReminder> plan)` <a id="tick"></a>

- **种类：** 方法
- **用途：** 在没有排程器的平台上看表。
- **输入：** 计划。
- **返回：** 无。
- **副作用：** 启动周期定时器；到点时弹出通知。
- **算法：** 每分钟检查一次：若今天的提醒尚未发布，且计划中的某个时间点已过，就记下日期并发布它。
- **用法：** 仅桌面，由 `reschedule` 调用。
- **说明：** 仅供本文件内部使用的助手。日期在发布之前就记入配置文件，因此一台一直开着的机器不会连着一小时每分钟弹一次。这是比手机更弱的承诺——应用必须开着——而设置的副标题写明了这一点。
