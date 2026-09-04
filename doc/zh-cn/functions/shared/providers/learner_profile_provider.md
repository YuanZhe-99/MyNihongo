# lib/shared/providers/learner_profile_provider.dart

两个派生 provider：学习者档案，以及现在该学什么。

两者都是普通的 `Provider` 而不是 notifier，因为它们都不拥有状态。进度文件才是状态；它们是它的函数，因此一次作答、一次同步或一次恢复都会让它们重算，所有监听的页面随之重建，不存在需要保持同步的第二个真相来源。

## 声明

| 声明 | 种类 | 层级 | 用途 |
|---|---|---|---|
| 库头 | 库文档 | B | 派生出学习者档案与复习队列。 |
| `learnerProfileProvider` | provider | B | 学习者的目标级别、每日目标与连续天数。 |
| [`reviewQueueProvider`](#reviewqueueprovider) | provider | A | 现在该学什么；数据加载完成前为 null。 |

## 文档

### `reviewQueueProvider` <a id="reviewqueueprovider"></a>

- **种类：** provider
- **用途：** 说明此刻有什么可学。
- **输入：** `progressDataProvider`、`contentCatalogProvider`、`learnerProfileProvider`。
- **返回：** `ReviewQueue?`——在进度文件与内容库都加载完成之前为 null。
- **副作用：** 自身没有；重算时会读取 `DateTime.now()`。
- **算法：** 监听三者，若任一异步来源仍为空则返回 null，否则调用 `ReviewQueue.build`。
- **使用：** `TodayCard`。
- **说明：** 加载期间返回 null 而不是空队列，这个区别正是关键：空队列意味着「没有到期的，做得好」，而在数据到达之前显示它，就是一句学习者会据以行动的假话。今日卡片对 null 改为渲染一个进度条。
