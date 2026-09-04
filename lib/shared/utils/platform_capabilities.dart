import 'package:flutter/foundation.dart';

/// What the current platform can do, in one place.
///
/// This is the only file in `lib/` that branches on the platform. Everything
/// here reads [defaultTargetPlatform] rather than `dart:io`'s `Platform`, so a
/// widget test can drive any branch through
/// `debugDefaultTargetPlatformOverride`, and so the rules stay testable on the
/// one host the project actually has. See `doc/en-us/platform-notes.md`.

/// Purpose: Report whether the app is running on a phone or tablet.
/// Inputs: None.
/// Returns: `bool` — true on Android and iOS.
/// Side effects: None.
/// Notes: Reads [defaultTargetPlatform], so a test override changes it.
bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Purpose: Report whether the app is running on a desktop.
/// Inputs: None.
/// Returns: `bool` — true on Windows, macOS and Linux.
/// Side effects: None.
/// Notes: The complement of [isMobilePlatform]; both are spelled out because
/// call sites read better naming the platform family they care about.
bool get isDesktopPlatform => !isMobilePlatform;

/// Purpose: Decide whether Settings shows the storage location row.
/// Inputs: None.
/// Returns: `bool` — false on mobile.
/// Side effects: None.
/// Notes: On a phone the path is a sandbox location the user can neither read
/// nor act on, so the row is noise; on a desktop it is a real folder they may
/// want to find. The custom storage path itself keeps working on every
/// platform — only the display is hidden.
bool get showsStorageLocation => !isMobilePlatform;

/// Purpose: Decide whether a deep link to the system speech settings exists.
/// Inputs: None.
/// Returns: `bool` — true on Android and Windows.
/// Side effects: None.
/// Notes: Used to offer "install a Japanese voice" as an action rather than
/// as plain text. Apple platforms have no documented deep link, so the message
/// there names the settings pane instead.
bool get canOpenSystemSpeechSettings =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.windows;

/// Purpose: Report whether an on-device generative model can exist here.
/// Inputs: None.
/// Returns: `bool` — true on Android only.
/// Side effects: None.
/// Notes: A coarse gate. The app reaches Gemini Nano through Android AICore,
/// which exists on no other platform, so every other platform answers
/// `GenAiStatus.unsupported` without touching the method channel. Whether a
/// given Android device actually has AICore and the model is a runtime
/// question answered by `AiAssistService.refreshStatus()`; see
/// `doc/en-us/android-aicore.md`.
bool get platformMayHaveOnDeviceModel =>
    defaultTargetPlatform == TargetPlatform.android;

/// Purpose: Report whether speech recognition can exist on this platform.
/// Inputs: None.
/// Returns: `bool` — false on Linux, which has no recognizer behind the plugin.
/// Side effects: None.
/// Notes: A coarse gate only. Whether a recognizer and a Japanese model are
/// actually present is decided at runtime by
/// `SpeechRecognitionService.ensureAvailable()`; this just avoids offering the
/// feature where it can never work.
bool get platformMayRecognizeSpeech =>
    defaultTargetPlatform != TargetPlatform.linux &&
    defaultTargetPlatform != TargetPlatform.fuchsia;

/// Purpose: Say whether the operating system will fire a reminder for us.
/// Inputs: None; reads `defaultTargetPlatform`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Android and iOS schedule notifications themselves, so a reminder
/// arrives whether or not the app is running. Everything else has to be
/// reminded from inside a running process — see
/// [platformRemindsFromInsideTheApp] — which is a genuinely weaker promise and
/// is why the two are named separately rather than being one flag.
bool get platformSchedulesReminders => isMobilePlatform;

/// Purpose: Say whether reminders depend on the app being open.
/// Inputs: None; reads `defaultTargetPlatform`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: The desktop path posts a notification from a timer in this process,
/// so a machine with the app closed is not reminded. The Settings subtitle
/// says so on those platforms rather than promising something the app cannot
/// deliver.
bool get platformRemindsFromInsideTheApp =>
    isDesktopPlatform &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);
