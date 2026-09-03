# lib/features/content/services/content_repository.dart

`ContentRepository.load` 通过 `rootBundle`（测试中可注入 `AssetBundle`）读取生成的单词文件、各等级语法文件与
假名注释，并解析为 `ContentCatalog`。`contentCatalogProvider` 是页面监视的 `FutureProvider`，每次运行加载一
次。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| 库头注释 | `library` | B | 读取并解析内置内容文件。 |
| `ContentRepository._` | 私有构造函数 | B | 阻止直接实例化，只暴露静态成员。 |
| `ContentRepository.load` | 静态方法 | B | 读取并解析全部内容文件为 `ContentCatalog`。 |
| `ContentRepository.parseContent` | 静态方法 | B | 把原始文件内容转为目录。 |
| `parseContent` | 顶层函数 | B | 在后台 isolate 上解析内容。 |

解码通过 `compute` 在后台 isolate 上进行，因此约 2 MB 的单词文件不会让启动后的第一帧丢失。单词资源以
`cache: false` 读取：它只解析一次，若留在资源包的字符串缓存中，会在整个进程生命周期内多占一份副本。
`parseInIsolate` 是带 `@visibleForTesting` 的接缝——控件测试把它设为 false，因为 `compute` 在 `FakeAsync` 下
永远不会完成；`test/content_repository_test.dart` 断言两条路径产生相同的目录。

`ContentSources` 是记录类型别名而不是三个参数，因为 `compute` 只接受一条消息。`contentCatalogProvider` 是带
普通文档注释的顶层 `final FutureProvider<ContentCatalog>`，不计入统计。
