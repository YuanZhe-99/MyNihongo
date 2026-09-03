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
  unavailable,

  /// The model is not on the device yet, and the system can fetch it.
  downloadable,

  /// The system is fetching the model.
  downloading,

  /// Ready to use.
  available,
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
  /// Notes: A platform error is `unavailable`, not an exception: "this device
  /// cannot" is exactly what a failure to ask means here.
  @override
  Future<GenAiStatus> status(GenAiFeature feature) async {
    if (!platformMayHaveOnDeviceModel) return GenAiStatus.unsupported;
    try {
      final answer = await _channel.invokeMethod<String>('status', {
        'feature': feature.name,
      });
      return switch (answer) {
        'available' => GenAiStatus.available,
        'downloadable' => GenAiStatus.downloadable,
        'downloading' => GenAiStatus.downloading,
        _ => GenAiStatus.unavailable,
      };
    } catch (_) {
      return GenAiStatus.unavailable;
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
