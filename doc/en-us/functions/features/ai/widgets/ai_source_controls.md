# lib/features/ai/widgets/ai_source_controls.dart

## AI sources and WebDAV privacy

MyApps-AI v0.6.0 is explicitly split into runtime, platform, models, local UI, sources and llama.cpp packages. Settings uses the unified section skeleton. Global source selection is device-local (`aiSourceSelection`), defaults to system AI, and MyNihongo has no online sources, so AI stays on the device. The shared `AiSourceRouter` (built by `createAiSourceRouter`, held as `MethodChannelGenAiBackend.sourceBackend`) shows friendly model names such as `Qwen: Qwen3.5 0.8B (Q4_K_M)`, lets the user rename a model, runs local models on the GPU only when the user turns that on and the device is verified (a GPU failure falls back to the CPU and is remembered), and accepts a custom Hugging Face GGUF model only after a mandatory warning. The device-local keys `aiComputePreference`, `aiGpuFailures`, `aiCustomModels` and `aiModelAliases` are never synced and never in backups. Qwen3.5 0.8B/2B Q4_K_M and Gemma 4 E2B Q4_0 run on the CPU by default. Downloads require explicit actions, use pinned URLs and SHA-256, and live under `ai_models/` outside data modules, sync, backup and ZIP. Model leases prevent removal during use. Source switches cancel old work and release model resources. The technical details stay behind the debug-mode setting and are a complete, copyable report of every included backend (`router.diagnostics()`). System proofreading remains independent in MyNihongo and always uses system AI.

WebDAV notice version 1 must be acknowledged on each device before connection testing, manual/force sync or background sync. The record is in device-local storage_config.json. Existing configurations stay intact while sync is paused; the WebDAV page displays a review banner. Declining saves no configuration and makes no request. JSON/images have no application-level encryption; HTTPS protects transit, HTTP does not. Wire format, locks and conflict policy remain unchanged.

## Declarations

| Declaration | Purpose |
|---|---|
| `const AiSourceControls({` | Bind the router and the selection callback. |
| `Widget build(BuildContext context) {` | Render the shared `MyAppsAiSourceSection` (source picker, local models entry, GPU switch; no online entry). |
| `Future<void> openAiLocalModels(BuildContext, AiSourceRouter, String?)` | Open the local models page with a rename menu and the "Add a custom model" entry (`MyAppsAddCustomModelPage`, Hugging Face GGUF, mandatory warning). |
| `MyAppsLocalModelLabels _modelLabels(AppLocalizations, AiSourceRouter)` | Build the model list labels; names come from the router (friendly name or alias). |
| `class _ModelMenu extends StatelessWidget` | Per-model menu: rename and, for custom models, remove from list. |
| `Widget build(BuildContext context) {` (`_ModelMenu`) | Build the popup menu. |
| `class _AliasDialog extends StatefulWidget` | Rename dialog that owns its text controller. |
| `Widget build(BuildContext context) {` (`_AliasDialogState`) | Build the dialog; pops the typed alias on save. |

`modelDisplayName` is removed: model names come from `AiSourceRouter.sourceName` (for example `Qwen: Qwen3.5 0.8B (Q4_K_M)`).
