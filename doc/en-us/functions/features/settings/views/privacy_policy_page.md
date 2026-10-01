# lib/features/settings/views/privacy_policy_page.dart

`PrivacyPolicyPage` shows the privacy policy in the active UI language — Japanese for `ja`,
Simplified Chinese for `zh`, Traditional Chinese for `zh_TW`, English otherwise — as selectable
text. Each language's text is its own string: the policy is the one document a reader is entitled
to rely on, so it is not run through the content conversion or a machine translation. The text
mirrors `PRIVACY_POLICY.md` at the repository
root; update both together. See [settings_page.md](settings_page.md) for how it is hosted.

Since 0.6.1 the page's scroll padding is wrapped in `navBarAwarePadding(context, const EdgeInsets.all(16))`, because this page is hosted in the Settings detail pane, where the Expressive floating bar can sit over its bottom edge (`SingleChildScrollView` and an explicit `padding` do not pick up the inset themselves). See [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage.new` | constructor | B | Create a privacy policy page instance. |
| `PrivacyPolicyPage.build` | method (widget build) | B | Build the privacy policy page in the active language. |
| `PrivacyPolicyPage._getText` | method | B | Pick the policy text for a locale with one switch on the language (`ja`, then `zh` split by country into `zh` and `zh_TW`); English is the fallback. |
