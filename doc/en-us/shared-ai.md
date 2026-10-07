# Shared AI

## Ownership

MyApps-AI v0.2.1 is pinned at `packages/myapps_ai`. Fresh checkouts run
`git submodule update --init --recursive` before `flutter pub get`.
The shared plugin registers com.yuanzhe.myapps_ai/genai; it owns Android Prompt,
Japanese keyboard proofreading and native cancellation. The app backend adapter
retains existing feature enums, diagnostics, failure types and public signatures.

## Compatibility

Prompt and proofreading remain independently available and downloadable. Explain
maps to shared generate with empty instructions, temperature 0.2 and topK 16.
Core information maps to shared info. The app gate remains Android-only; this
migration adds no Apple AI feature. Existing practice scheduling, prompts, output
parsers, scoring, progress and generated-question exclusions remain app-owned.
Failures outside the app's existing enum map to failed; cancellation and length
failures retain their existing meaning. The native bridge now checks cancellation
before publishing success and retains the busy slot until a cancelled job exits.

## Verification

The shared gate claims occupancy before status awaits, cancels on timeout and
rejects obsolete replies. Refresh and download stop querying after disable.
Practice-level interactive ordering and bounded background retries remain app-owned.

Shared CI verifies Android release and Apple builds/weak linking. The consumer
backend tests exercise the updated generate/info protocol and capability reports;
app tests preserve feature isolation and teaching behavior. Consumer release
builds and device inference remain separate verification.

## AI sources and WebDAV privacy

MyApps-AI v0.5.2 is explicitly split into runtime, platform, models, local UI and llama.cpp packages. Settings uses the unified section skeleton. Global source selection is device-local (`aiSourceSelection`), defaults to system AI, and never chooses online as fallback. Qwen3.5 0.8B/2B Q4_K_M and Gemma 4 E2B Q4_0 run on CPU. Downloads require explicit actions, use pinned URLs and SHA-256, and live under `ai_models/` outside data modules, sync, backup and ZIP. Model leases prevent removal during use. Source switches cancel old work and release model resources. System proofreading remains independent in MyNihongo.

WebDAV notice version 1 must be acknowledged on each device before connection testing, manual/force sync or background sync. The record is in device-local storage_config.json. Existing configurations stay intact while sync is paused; the WebDAV page displays a review banner. Declining saves no configuration and makes no request. JSON/images have no application-level encryption; HTTPS protects transit, HTTP does not. Wire format, locks and conflict policy remain unchanged.
