# lib/features/learn/views/learn_page.dart

`LearnPage` is the first tab and the app's home: a dashboard of four cards — catalog counts (kana,
words, grammar points), progress counts (items tracked and mastered, or an honest "nothing tracked
yet"), quick links to the three reference tabs, and the roadmap. It watches
`contentCatalogProvider` and `progressDataProvider`; the cards flow one or two across by
`ruleCardMinWidth`, gated on `canSplitLayout`. Since 0.6.0 its app bar carries the profile avatar (`ProfileAvatar`, radius 16) as `leading`, to the left of the title; tapping it runs `context.go('/settings')`. It is the only page with that avatar. In Phase 3 this page becomes the lesson path. See
[../../../../features/learning-progress.md](../../../../features/learning-progress.md).

Since 0.6.1 the list's padding is `navBarAwarePadding(context, EdgeInsets.fromLTRB(16, 8, 16, shellListBottomInset(width)))`: with the Expressive floating bottom bar the page draws behind the bar, and the wrapper adds the bar's height so the last content can scroll above it. See [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LearnPage.new` | constructor | B | Create a learn page instance. |
| `LearnPage.build` | method (`ConsumerWidget` build) | B | Build the home tab: what the app holds, what the user has done, where to start. |
| `LearnPage._card` | method (widget helper) | B | Render one dashboard card (icon, title, body). |
| `LearnPage._line` | method (widget helper) | B | Render one line of body text inside a card. |
| `LearnPage._link` | method (widget helper) | B | Render one quick-start row that navigates to a tab with `context.go`. |
