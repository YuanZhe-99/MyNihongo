import 'package:flutter/services.dart';

import '../../../shared/utils/platform_capabilities.dart';

/// Which on-device model a call is about.
///
/// Two separate ML Kit features with separate downloads and separate
/// availability: a device can have one and not the other, so nothing here
/// treats "AI" as a single switchable thing.
enum GenAiFeature {
  /// The Prompt API — free-form generation, used for explanations.
  prompt,

  /// The Proofreading API — corrects one short Japanese sentence.
  proofread,
}

/// What a feature can do on this device, right now.
enum GenAiStatus {
  /// This platform has no on-device model at all. Never asked the device.
  unsupported,

  /// The device cannot run this feature — no AICore, or an unsupported model.
  /// AICore was asked and said no.
  unavailable,

  /// AICore could not be asked at all: the call threw. A different fact from
  /// [unavailable], with a different fix, and the two looked identical until a
  /// phone that has AICore reported having no model.
  unreachable,

  /// The model is not on the device yet, and the system can fetch it.
  downloadable,

  /// The system is fetching the model.
  downloading,

  /// Ready to use.
  available,

  /// AICore answered with a status this build has no name for.
  ///
  /// Reported as itself rather than folded into [unavailable]. The set of
  /// statuses has grown before, and reading a value the app does not know as
  /// a refusal is how a device that works came to be told it was unsupported.
  unknown,
}

/// Why a generation attempt did not produce an answer.
enum GenAiFailure {
  /// The feature is not usable on this device.
  unavailable,

  /// Another request is already running.
  busy,

  /// The model ran but produced nothing usable, or the platform errored.
  failed,

  /// The request was cancelled, usually because the page was closed.
  cancelled,

  /// The input was longer than the API accepts.
  tooLong,

  /// The model did not answer in time.
  timeout,
}

/// Thrown by a backend when a call cannot produce a result.
class GenAiException implements Exception {
  const GenAiException(this.failure, [this.message]);

  /// Which failure this is, for the UI to word.
  final GenAiFailure failure;

  /// The platform's own message, for logs only — never shown to the learner.
  final String? message;

  @override
  String toString() => 'GenAiException(${failure.name}, $message)';
}

/// One feature's status plus what the device said about it.
///
/// The extra fields exist for one reason: the published device lists differ per
/// API and are a floor rather than the truth, so "not available on this device"
/// is not a diagnosis. The raw `FeatureStatus` code, or the exception when the
/// call threw, is what separates a phone that is simply not on the Prompt API's
/// list from one where something is broken.
class GenAiStatusReport {
  /// Purpose: Describe one feature's availability.
  /// Inputs: `status`; `code` — the platform's own value, -1 when it threw;
  /// `detail` — a short untranslated line, or null when there is nothing to
  /// explain.
  /// Returns: A new `GenAiStatusReport` instance.
  /// Side effects: None.
  /// Notes: `detail` is deliberately not localized: it is an identifier to
  /// quote in a bug report, not prose to read.
  const GenAiStatusReport(
    this.status, {
    this.code = -1,
    this.detail,
    this.variant,
    this.refused,
    this.baseModelName,
    this.tokenLimit,
  });

  /// What the feature can do.
  final GenAiStatus status;

  /// The platform's raw status value; -1 when the call threw.
  final int code;

  /// A short diagnostic line, or null.
  final String? detail;

  /// Which model variant answered, such as `stable/full`; null when none did
  /// and on every feature that has only one.
  final String? variant;

  /// The variants the device refused, in the order they were tried, or null.
  ///
  /// This is the field the whole diagnostic hangs on. "Not available on this
  /// device" was the same sentence whether one model had been asked or four,
  /// and that ambiguity survived two releases.
  final String? refused;

  /// The name of the model actually serving, when one is; null otherwise.
  final String? baseModelName;

  /// The serving model's token limit, when one is serving; null otherwise.
  final int? tokenLimit;

  /// A report for a platform that was never asked.
  static const unsupported = GenAiStatusReport(GenAiStatus.unsupported);
}

/// What the AICore system service on this device is, if anything.
class GenAiCoreInfo {
  /// Purpose: Describe the device's AICore installation.
  /// Inputs: `installed`, `versionName`, `sdk`, `device`.
  /// Returns: A new `GenAiCoreInfo` instance.
  /// Side effects: None.
  /// Notes: Reading this needs the manifest's `<queries>` entry for
  /// `com.google.android.aicore`; without it every device answers
  /// `installed: false`.
  const GenAiCoreInfo({
    required this.installed,
    this.versionName,
    this.sdk,
    this.device,
    this.compatible,
  });

  /// Whether the AICore package is present.
  final bool installed;

  /// The AICore build, such as `aicore_20260723.00_RC11`.
  final String? versionName;

  /// The device's Android API level.
  final int? sdk;

  /// Manufacturer and model, as the system reports them.
  final String? device;

  /// Whether ML Kit considers AICore usable here, or null when it could not
  /// be asked.
  ///
  /// On a device that refuses every model variant this is what separates
  /// "AICore is absent or too old" from "AICore is fine, this model is not
  /// offered here" — two facts with different fixes that no public API
  /// distinguishes.
  final bool? compatible;

  /// Purpose: Read the map the platform channel sends.
  /// Inputs: `json`.
  /// Returns: `GenAiCoreInfo?` — null when the platform sent nothing usable.
  /// Side effects: None.
  /// Notes: None.
  static GenAiCoreInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    return GenAiCoreInfo(
      installed: json['installed'] == true,
      versionName: json['versionName']?.toString(),
      sdk: json['sdk'] is int ? json['sdk'] as int : null,
      device: json['device']?.toString(),
      compatible: json['compatible'] is bool
          ? json['compatible'] as bool
          : null,
    );
  }
}

/// The seam between [AiAssistService] and the platform's generative models.
///
/// It exists for the same reason the speech and text-to-speech seams do: a
/// `flutter_test` run has no AICore, and everything worth testing — the
/// enabled gate, the status handling, the prompt, the parsing — is on the
/// service's side of it.
abstract class GenAiBackend {
  /// Purpose: Ask what a feature can do on this device.
  /// Inputs: `feature`.
  /// Returns: `Future<GenAiStatus>`.
  /// Side effects: Queries the platform.
  /// Notes: Never throws; an unreachable platform answers `unavailable`.
  Future<GenAiStatus> status(GenAiFeature feature);

  /// Purpose: Ask the system to fetch a feature's model.
  /// Inputs: `feature`, and `onProgress` called with bytes downloaded and the
  /// total when it is known (-1 when it is not).
  /// Returns: `Future<bool>` — true when the model is ready afterwards.
  /// Side effects: The **system** downloads a model over the network.
  /// Notes: The app never downloads anything itself; it asks AICore to. That
  /// distinction is what the privacy policy states.
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  });

  /// Purpose: Generate one answer.
  /// Inputs: `prompt`, and `maxOutputTokens`.
  /// Returns: `Future<String>` — possibly empty.
  /// Side effects: Runs a model on the device.
  /// Notes: Throws [GenAiException] rather than returning a failure, so a
  /// caller cannot mistake an error for an empty answer.
  Future<String> explain(String prompt, {int maxOutputTokens});

  /// Purpose: Ask for corrected versions of one short Japanese sentence.
  /// Inputs: `text`.
  /// Returns: `Future<List<String>>` — best first, possibly empty.
  /// Side effects: Runs a model on the device.
  /// Notes: Throws [GenAiException] on failure.
  Future<List<String>> proofread(String text);

  /// Purpose: Stop whatever is running.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the in-flight platform request.
  /// Notes: Safe to call when nothing is running.
  Future<void> cancel();

  /// Purpose: Ask what a feature can do, and what the device said about it.
  /// Inputs: `feature`.
  /// Returns: `Future<GenAiStatusReport>`.
  /// Side effects: Queries the platform.
  /// Notes: Given a body rather than left abstract so a backend that has
  /// nothing to add — every test fake — keeps working unchanged. Never throws.
  Future<GenAiStatusReport> statusReport(GenAiFeature feature) async =>
      GenAiStatusReport(await status(feature));

  /// Purpose: Describe the device's AICore installation.
  /// Inputs: None.
  /// Returns: `Future<GenAiCoreInfo?>` — null where the question is meaningless.
  /// Side effects: Queries the platform.
  /// Notes: Given a body for the same reason as [statusReport]. Never throws.
  Future<GenAiCoreInfo?> coreInfo() async => null;
}

/// The real backend, talking to `GenAiChannel` on the Android side.
///
/// Every method short-circuits on a platform that has no on-device model, so
/// the channel is never touched on Windows, macOS or iOS — where it does not
/// exist and every call would throw `MissingPluginException`.
class MethodChannelGenAiBackend implements GenAiBackend {
  MethodChannelGenAiBackend([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  /// The channel name, matched by `GenAiChannel.CHANNEL` in Kotlin.
  static const channelName = 'com.yuanzhe.my_nihongo/genai';

  final MethodChannel _channel;

  void Function(int bytes, int total)? _onProgress;
  bool _listening = false;

  /// Purpose: Ask the platform for a feature's status.
  /// Inputs: `feature`.
  /// Returns: `Future<GenAiStatus>`.
  /// Side effects: One channel call.
  /// Notes: The full answer is in [statusReport]; this drops the diagnostics.
  @override
  Future<GenAiStatus> status(GenAiFeature feature) async =>
      (await statusReport(feature)).status;

  /// Purpose: Ask the platform for a feature's status and what it said.
  /// Inputs: `feature`.
  /// Returns: `Future<GenAiStatusReport>`.
  /// Side effects: One channel call.
  /// Notes: A platform error is [GenAiStatus.unreachable] rather than
  /// `unavailable`. The two used to share an answer, and the cost of that was a
  /// phone with AICore installed reporting it had no on-device model, with
  /// nothing anywhere to say which of the two had happened.
  @override
  Future<GenAiStatusReport> statusReport(GenAiFeature feature) async {
    if (!platformMayHaveOnDeviceModel) return GenAiStatusReport.unsupported;
    try {
      final answer = await _channel.invokeMapMethod<String, Object?>('status', {
        'feature': feature.name,
      });
      final name = answer?['status']?.toString();
      final status = switch (name) {
        'available' => GenAiStatus.available,
        'downloadable' => GenAiStatus.downloadable,
        'downloading' => GenAiStatus.downloading,
        'unreachable' => GenAiStatus.unreachable,
        'unknown' => GenAiStatus.unknown,
        _ => GenAiStatus.unavailable,
      };
      return GenAiStatusReport(
        status,
        code: answer?['code'] is int ? answer!['code'] as int : -1,
        detail: answer?['detail']?.toString(),
        // Absent rather than wrong: an older platform side, or the
        // proofreading feature, simply sends none of these.
        variant: answer?['variant']?.toString(),
        refused: answer?['refused']?.toString(),
        baseModelName: answer?['baseModelName']?.toString(),
        tokenLimit: answer?['tokenLimit'] is int
            ? answer!['tokenLimit'] as int
            : null,
      );
    } on PlatformException catch (error) {
      return GenAiStatusReport(
        GenAiStatus.unreachable,
        detail: '${error.code}: ${error.message}',
      );
    } catch (error) {
      return GenAiStatusReport(
        GenAiStatus.unreachable,
        detail: error.runtimeType.toString(),
      );
    }
  }

  /// Purpose: Read the device's AICore installation.
  /// Inputs: None.
  /// Returns: `Future<GenAiCoreInfo?>`.
  /// Side effects: One channel call.
  /// Notes: Null off Android and whenever the call fails — this is a
  /// diagnostic, and failing to gather one must never break the page showing
  /// it.
  @override
  Future<GenAiCoreInfo?> coreInfo() async {
    if (!platformMayHaveOnDeviceModel) return null;
    try {
      return GenAiCoreInfo.fromJson(
        await _channel.invokeMapMethod<String, Object?>('aicore'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Ask the system to fetch a feature's model.
  /// Inputs: `feature`, `onProgress`.
  /// Returns: `Future<bool>`.
  /// Side effects: The system downloads a model; progress arrives as method
  /// calls from the platform.
  /// Notes: The progress handler is registered lazily and once, because a
  /// download is the only thing that sends calls back the other way.
  @override
  Future<bool> download(
    GenAiFeature feature, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    if (!platformMayHaveOnDeviceModel) {
      throw const GenAiException(GenAiFailure.unavailable);
    }
    _onProgress = onProgress;
    if (!_listening) {
      _channel.setMethodCallHandler(_handlePlatformCall);
      _listening = true;
    }
    try {
      final done = await _channel.invokeMethod<bool>('download', {
        'feature': feature.name,
      });
      return done ?? false;
    } on PlatformException catch (e) {
      throw GenAiException(_failureFor(e.code), e.message);
    } finally {
      _onProgress = null;
    }
  }

  /// Purpose: Generate one answer.
  /// Inputs: `prompt`, `maxOutputTokens`.
  /// Returns: `Future<String>`.
  /// Side effects: Runs a model on the device.
  /// Notes: `temperature` and `topK` are low and fixed: this asks for an
  /// explanation of a fact the deterministic pipeline already established, and
  /// variety in that answer is not a feature.
  @override
  Future<String> explain(String prompt, {int maxOutputTokens = 256}) async {
    if (!platformMayHaveOnDeviceModel) {
      throw const GenAiException(GenAiFailure.unavailable);
    }
    try {
      final text = await _channel.invokeMethod<String>('explain', {
        'prompt': prompt,
        'maxOutputTokens': maxOutputTokens,
        'temperature': 0.2,
        'topK': 16,
      });
      return text ?? '';
    } on PlatformException catch (e) {
      throw GenAiException(_failureFor(e.code), e.message);
    }
  }

  /// Purpose: Ask for corrected versions of one short Japanese sentence.
  /// Inputs: `text`.
  /// Returns: `Future<List<String>>`.
  /// Side effects: Runs a model on the device.
  /// Notes: None.
  @override
  Future<List<String>> proofread(String text) async {
    if (!platformMayHaveOnDeviceModel) {
      throw const GenAiException(GenAiFailure.unavailable);
    }
    try {
      final results = await _channel.invokeListMethod<String>('proofread', {
        'text': text,
      });
      return results ?? const [];
    } on PlatformException catch (e) {
      throw GenAiException(_failureFor(e.code), e.message);
    }
  }

  /// Purpose: Stop whatever is running.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the in-flight platform request.
  /// Notes: Errors are swallowed: cancelling is best-effort by nature, and
  /// there is nothing a caller could do about a failed cancel.
  @override
  Future<void> cancel() async {
    if (!platformMayHaveOnDeviceModel) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (_) {
      // Nothing to do: the request either finished or will be discarded.
    }
  }

  /// Purpose: Receive download progress from the platform.
  /// Inputs: `call`.
  /// Returns: None.
  /// Side effects: Calls the current progress callback.
  /// Notes: Internal helper used within this file only.
  Future<void> _handlePlatformCall(MethodCall call) async {
    if (call.method != 'downloadProgress') return;
    final args = call.arguments;
    if (args is! Map) return;
    _onProgress?.call(
      (args['bytes'] as num?)?.toInt() ?? 0,
      (args['total'] as num?)?.toInt() ?? -1,
    );
  }

  /// Purpose: Map a platform error code to a failure.
  /// Inputs: `code`.
  /// Returns: `GenAiFailure`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The codes are the ones
  /// `GenAiChannel` sends; anything else is `failed`, which is the honest
  /// answer for an error neither side recognises.
  static GenAiFailure _failureFor(String code) => switch (code) {
    'unavailable' => GenAiFailure.unavailable,
    'busy' => GenAiFailure.busy,
    'cancelled' => GenAiFailure.cancelled,
    'tooLong' => GenAiFailure.tooLong,
    _ => GenAiFailure.failed,
  };
}
