# lib/features/content/services/content_repository.dart

`ContentRepository.load` 通过 `rootBundle`（或测试中注入的 `AssetBundle`）读取 `assets/content/vocab_seed.json` 和 `assets/content/grammar_seed.json`，并把它们解析为 `ContentCatalog`。`contentCatalogProvider` 是页面监视的 `FutureProvider`；每次运行加载一次。解析在调用 isolate 上运行——对种子来说足够，JMdict 规模的目录到来时移到 `compute`。见 [../../../../features/content-catalog.md](../../../../features/content-catalog.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `ContentRepository._` | 私有构造函数 | B | 阻止直接实例化，只暴露静态成员。 |
| `ContentRepository.load` | 静态方法 | B | 读取并解析两个内容文件为 `ContentCatalog`。 |

`contentCatalogProvider` 是带普通文档注释的顶层 `final FutureProvider<ContentCatalog>`；不计入。
