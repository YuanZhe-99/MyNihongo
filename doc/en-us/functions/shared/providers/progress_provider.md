# lib/shared/providers/progress_provider.dart

Declares `progressDataProvider`, a `FutureProvider<ProgressData>` over `NihongoStorage.load()`.
Pages that show progress watch it and refresh it after a save or when `AutoSyncService` reports
that sync wrote local data. See
[../../../features/learning-progress.md](../../../features/learning-progress.md).

## Declarations

The file contains a single top-level `final` with an ordinary doc comment and no functions, so it
carries no Function Explanation Layer entries.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `progressDataProvider` | top-level `final FutureProvider<ProgressData>` | — | The user's progress file, read from disk. |
