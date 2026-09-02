# lib/features/learn/views/learn_page.dart

`LearnPage` is the first tab and the app's home: a dashboard of four cards — catalog counts (kana,
words, grammar points), progress counts (items tracked and mastered, or an honest "nothing tracked
yet"), quick links to the three reference tabs, and the roadmap. It watches
`contentCatalogProvider` and `progressDataProvider`; the cards flow one or two across by
`ruleCardMinWidth`, gated on `canSplitLayout`. In Phase 3 this page becomes the lesson path. See
[../../../../features/learning-progress.md](../../../../features/learning-progress.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LearnPage.new` | constructor | B | Create a learn page instance. |
| `LearnPage.build` | method (`ConsumerWidget` build) | B | Build the home tab: what the app holds, what the user has done, where to start. |
| `LearnPage._card` | method (widget helper) | B | Render one dashboard card (icon, title, body). |
| `LearnPage._line` | method (widget helper) | B | Render one line of body text inside a card. |
| `LearnPage._link` | method (widget helper) | B | Render one quick-start row that navigates to a tab with `context.go`. |
