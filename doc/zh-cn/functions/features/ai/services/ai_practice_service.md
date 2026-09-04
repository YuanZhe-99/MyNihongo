# lib/features/ai/services/ai_practice_service.dart

为设备上仅有的那一个模型安排轮次。

`AiAssistService` 一次只允许一次生成，因此两个都想用它的功能必须排队。这里的规则是：**学习者的请求优先**。

它有意不 import 任何存储或进度 provider：生成的内容不写入任何记录，并且有一条测试通过读取本文件自身的 import 列表来断言这一点。

使用方：`why_wrong.dart`、`generated_examples.dart`。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| `AiPracticeService` | 类 | B | 轮流运行各项练习任务。 |
| `AiPracticeService.instance` | 字段 | B | 全应用实例。 |
| `AiPracticeService.setInstanceForTest` | 方法 | B | 在测试中替换它。 |
| `retryDelay`、`maxRetries` | 常量 | B | 后台任务如何等待与放弃。 |
| `AiPracticeService.canRun` | getter | B | 模型是否可以被询问。 |
| [`AiPracticeService.run`](#run) | 方法 | A | 运行一个学习者正在等待的提示。 |
| [`AiPracticeService.runInBackground`](#bg) | 方法 | A | 运行一个没人在等的提示。 |

## 文档

### `Future<String> run(String prompt)` <a id="run"></a>

- **种类：** 方法
- **用途：** 运行一个学习者正在等待的提示。
- **输入：** 提示。
- **返回：** 模型的回复；失败时抛出 `GenAiException`。
- **副作用：** 在设备上运行模型。
- **算法：** 接在上一个交互 future 之后，因此请求按发出的顺序运行。
- **用法：** 每一个会生成内容的按钮。
- **说明：** 交互请求彼此排队，而不是以「忙」失败。连点两个按钮的人应该得到两个答案而不是一个错误，而代价是等一秒，而不是一个他们还得去理解的失败。

### `Future<String?> runInBackground(String prompt)` <a id="bg"></a>

- **种类：** 方法
- **用途：** 运行一个没人在等的提示。
- **输入：** 提示。
- **返回：** 回复；始终没轮到时为 null。
- **副作用：** 可能在等待之后在设备上运行模型。
- **算法：** 先等待任何交互工作，然后在模型忙时重试几次。
- **用法：** 学习者在做别的事情时生成的任何内容。
- **说明：** **它会安静地放弃。** 返回 null 而不是抛出正是要点：没有谁在等它，也就没有谁需要被告知；而从后台任务里冒出来的错误，会打断学习者正在做的事。
