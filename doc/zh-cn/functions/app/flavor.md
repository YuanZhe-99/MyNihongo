# lib/app/flavor.dart

`AppFlavor` 把 `FLAVOR` Dart define（`store` 或默认的 `full`）读入两个编译期常量 `isStore` 和 `isFull`。目前没有任何功能以它为门控；它存在是为了像兄弟应用一样区分商店构建，并让未来的在线功能有现成的门控。见 [../../architecture.md](../../architecture.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `AppFlavor._` | 私有构造函数 | B | 阻止直接实例化，只暴露静态成员。 |
