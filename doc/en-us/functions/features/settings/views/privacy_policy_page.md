# lib/features/settings/views/privacy_policy_page.dart

`PrivacyPolicyPage` shows the privacy policy in the active UI language — Simplified Chinese for
`zh`, English otherwise — as selectable text. The text mirrors `PRIVACY_POLICY.md` at the repository
root; update both together. See [settings_page.md](settings_page.md) for how it is hosted.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage.new` | constructor | B | Create a privacy policy page instance. |
| `PrivacyPolicyPage.build` | method (widget build) | B | Build the privacy policy page in the active language. |
| `PrivacyPolicyPage._getText` | method | B | Pick the policy text for a locale; English is the fallback. |
