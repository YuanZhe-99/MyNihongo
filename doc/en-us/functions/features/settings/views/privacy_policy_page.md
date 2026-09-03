# lib/features/settings/views/privacy_policy_page.dart

`PrivacyPolicyPage` shows the privacy policy in the active UI language — Simplified Chinese for
`zh`, Traditional Chinese for `zh_TW`, English otherwise — as selectable text. Each language's text
is its own string: the policy is the one document a reader is entitled to rely on, so it is not
run through the content conversion. The text mirrors `PRIVACY_POLICY.md` at the repository
root; update both together. See [settings_page.md](settings_page.md) for how it is hosted.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage.new` | constructor | B | Create a privacy policy page instance. |
| `PrivacyPolicyPage.build` | method (widget build) | B | Build the privacy policy page in the active language. |
| `PrivacyPolicyPage._getText` | method | B | Pick the policy text for a locale, by language and then country; English is the fallback. |
