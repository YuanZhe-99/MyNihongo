# lib/features/settings/views/privacy_policy_page.dart

`PrivacyPolicyPage` 以当前 UI 语言显示隐私政策——`ja` 为日语，`zh` 为简体中文，`zh_TW` 为繁体中文，其余为英语——作为可选择文本。每种语言的文本都是独立的字符串：隐私政策是读者有权据以信赖的那份文件，因此它不走内容的转换流程，也不经机器翻译。文本镜像仓库根目录的 `PRIVACY_POLICY.md`；两者一起更新。承载方式见 [settings_page.md](settings_page.md)。

自 0.6.1 起，该页面的滚动 padding 被 `navBarAwarePadding(context, const EdgeInsets.all(16))` 包裹，因为该页面承载在设置的详情窗格中，Expressive 悬浮栏可能盖住它的底边（`SingleChildScrollView` 加显式 `padding` 不会自己加上这段内边距）。见 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage.new` | 构造函数 | B | 创建隐私政策页面实例。 |
| `PrivacyPolicyPage.build` | 方法（widget build） | B | 以当前语言构建隐私政策页面。 |
| `PrivacyPolicyPage._getText` | 方法 | B | 用一个针对语言的 switch 为 locale 选择政策文本（先 `ja`，然后是按国家拆分为 `zh` 与 `zh_TW` 的 `zh`）；英语是回落。 |


当前接入 MyApps-AI v0.5.2，显式注入平台后端，使用应用所属来源路由与统一设置骨架。WebDAV 入口在任何网络请求前要求设备本地提醒确认；具体见同步概念文档。
