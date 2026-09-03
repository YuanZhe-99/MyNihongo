# lib/app/router.dart

声明 `appRouter`，即应用的 `GoRouter`：`initialLocation: '/learn'`，以及一个 `ShellRoute`，其 builder 把每个标签包在 `ShellScaffold` 中，按显示顺序持有五个标签路由——`/learn`、`/kana`、`/vocab`、`/grammar`、`/settings`。`ShellScaffold.routes` 持有同一列表；两者靠人工保持同步。目前没有非标签路由。见 [../../architecture.md](../../architecture.md)。

## 声明

该文件只包含一个带普通文档注释的顶层 `final`（`appRouter`），没有函数，因此不携带函数解释层条目。

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `appRouter` | 顶层 `final GoRouter` | — | `MyNihongoApp` 消费的路由配置。 |

`buildAppRouter({initialLocation})` 在 `PLAN.md` M1.3 中取代了顶层的 `appRouter`。`main()` 在 `runApp`
**之前**从设备偏好读取上次所在的标签并传入此处，因此应用直接在用户离开的位置打开，而不是先显示“学习”再跳转。
根组件只构建一次路由器并保存在其状态中：`GoRouter` 拥有导航历史，若在主题或语言变化时重建，会把用户在会话中途
送回初始标签。
