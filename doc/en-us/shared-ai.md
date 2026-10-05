# Shared AI

## Ownership

MyApps-AI v0.2.0 is pinned at `packages/myapps_ai`. Fresh checkouts run
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

Shared CI verifies Android release and Apple builds/weak linking. The consumer
backend tests exercise the updated generate/info protocol and capability reports;
app tests preserve feature isolation and teaching behavior. Consumer release
builds and device inference remain separate verification.
