# lib/features/settings/views/privacy_policy_page.dart

`PrivacyPolicyPage` 以当前 UI 语言显示隐私政策——`zh` 为简体中文，其余为英语——作为可选择文本。文本镜像仓库根目录的 `PRIVACY_POLICY.md`；两者一起更新。承载方式见 [settings_page.md](settings_page.md)。

## 声明

| 声明 | 类型 | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage.new` | 构造函数 | B | 创建隐私政策页面实例。 |
| `PrivacyPolicyPage.build` | 方法（widget build） | B | 以当前语言构建隐私政策页面。 |
| `PrivacyPolicyPage._getText` | 方法 | B | 为语言选择政策文本；英语是回落。 |
