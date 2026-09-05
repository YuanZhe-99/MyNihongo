# lib/features/drills/services/readiness_rules.dart

把最近的卷子变成一个档位——还不到、接近了、看起来可以了——按计分组给出，也给整个级别给出。

**这不是 JLPT 成绩，也不可能是。** JEES 不公布原始分到量表分的换算，所以没有任何应用能算出真正的
成绩。能算的是学习者在本应用所写题目上的正确率，诚实的呈现方式是一个档位加上说明——这就是本文件里
每个档位名称都是定性的、并且没有任何数字送到屏幕上的原因。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| library header | library doc | B | 把最近的卷子变成每个计分组的档位。 |
| `readinessReady` | 常量 | B | 一个计分组要达到多少正确率才算"可以了"。 |
| `readinessClose` | 常量 | B | 低于多少正确率就还谈不上"接近了"。 |
| `readinessMinAsked` | 常量 | B | 一个计分组要有多少题才谈得上给档位。 |
| `readinessMinCoverage` | 常量 | B | 要接触过多少目录内容才允许说"可以了"。 |
| `ReadinessBand` | 枚举 | B | 学习者看起来准备到什么程度。 |
| `ReadinessEstimate` | 类 | B | 应用愿意就学习者的备考程度说的话。 |
| [`build`](#build) | 静态方法 | A | 算出各个档位。 |

## 文档

### `static ReadinessEstimate build({required WeaknessReport report, required LevelStructure structure, double coverage = 1, bool hasJapaneseVoice = true})` <a id="build"></a>

- **种类：** 静态方法
- **用途：** 算出各个档位。
- **输入：** `report`；该级别的 `structure`；`coverage`——学习者在该级别目录里已有学习记录的比例；
  设备是否有日语语音。
- **返回：** `ReadinessEstimate`；报告为空时返回 `unknown`。
- **副作用：** 无。
- **算法：** 对每个计分组，把它包含的各部分的统计相加。只含听力且没有语音的组是 `unmeasured`；
  题数低于 `readinessMinAsked` 的组是 `unknown`；否则由正确率决定 `ready`、`close` 还是 `notYet`。
  整体档位是可测量的组里最差的那个，当它是 `ready` 而覆盖率低于 `readinessMinCoverage` 时压回
  `close`。
- **用法：** `readinessProvider`，并经由它到达学习页卡片。
- **注意：** 有四个决定，每一个都是关于这个估计拒绝说什么。

  **整体档位取最差的组，不是取平均。** 这照搬了考试自己的规则——任何一个计分组不及格，整个级别就
  不及格，别的组考得再好也一样——而且这是真实计分里应用唯一能诚实复现的部分，因为它是一条规则而
  不是一个数字。

  **只要有一个组是 unknown，整个估计就是 unknown。** 三个组里用两个组算出来的整体档位，是在描述
  一份没有人考过的卷子。

  **没有日语语音时听力是 `unmeasured`，并且不会把整体档位拉下来。** 学习者不是听力差，是设备问不
  了。它也不是 `unknown`——那意味着"多做几套卷子"，而这条建议学习者根本没法照做。

  **覆盖率只能把估计压下去，永远不能把它抬上来。** 答得好说明的是关于被问到的那些题；对于一个词汇
  大多没见过的级别，它说明不了多少。`cappedByCoverage` 被一路带到界面上，好让屏幕能说出*为什么*
  不肯说"可以了"——一个正确率九成的学习者看到没有任何解释的"接近了"，读起来像 bug 而不像说明。

`readinessReady` 与 `checkpointPassAccuracy` 是同一个数字，而且是故意的：应用在开启下一个课程单元
时已经认定十分之七意味着"这个学会了"，同一个论断用两个不同的阈值，等于应用在跟自己唱反调。
