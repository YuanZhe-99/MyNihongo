import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/platform_capabilities.dart';
import 'genai_backend.dart';

/// How far a model download has got.
@immutable
class GenAiDownload {
  const GenAiDownload({required this.bytes, required this.total});

  /// Bytes fetched so far.
  final int bytes;

  /// Total bytes, or -1 when the system has not said.
  final int total;

  /// The fraction done, or null when the total is unknown.
  double? get fraction => total > 0 ? (bytes / total).clamp(0.0, 1.0) : null;
}

/// Owns the on-device AI policy: whether it may run at all, what each feature
/// can do right now, and the one-at-a-time rule.
///
/// A singleton with an injectable backend, like `TtsService` and
/// `SpeechRecognitionService`, so a widget test drives every branch without a
/// device. **The load-bearing rule is the first line of every method that
/// generates: when the learner has not turned the feature on, the backend is
/// never called at all** — not called and ignored, not called and discarded.
class AiAssistService extends ChangeNotifier {
  AiAssistService({GenAiBackend? backend})
    : _backend = backend ?? MethodChannelGenAiBackend();

  /// The app-wide instance.
  static AiAssistService instance = AiAssistService();

  /// Purpose: Replace the singleton for a test.
  /// Inputs: `service`.
  /// Returns: None.
  /// Side effects: Points [instance] at another service.
  /// Notes: Test-only. Production code constructs the default one once.
  @visibleForTesting
  static void setInstanceForTest(AiAssistService service) => instance = service;

  /// How long one generation may take before it is given up on.
  ///
  /// A first inference after a cold start is slow — the model has to be paged
  /// in — so this is generous. It exists so a wedged request cannot leave a
  /// spinner on the screen forever, not to police the model's speed.
  static const timeout = Duration(seconds: 45);

  final GenAiBackend _backend;

  bool _enabled = false;
  final Map<GenAiFeature, GenAiStatusReport> _status = {};
  GenAiCoreInfo? _coreInfo;
  GenAiDownload? _download;
  GenAiFeature? _downloading;
  bool _busy = false;

  /// Whether the learner turned on-device AI on. Off until they do.
  bool get enabled => _enabled;

  /// Whether a generation or a download is running.
  bool get busy => _busy;

  /// The feature currently downloading, if any.
  GenAiFeature? get downloadingFeature => _downloading;

  /// Progress of the running download, if any.
  GenAiDownload? get downloadProgress => _download;

  /// Purpose: Report what a feature can do, as last asked.
  /// Inputs: `feature`.
  /// Returns: `GenAiStatus`.
  /// Side effects: None.
  /// Notes: `unsupported` until [refreshStatus] has run, which is also the
  /// right answer on every platform that has no on-device model.
  GenAiStatus statusOf(GenAiFeature feature) => reportOf(feature).status;

  /// Purpose: Report a feature's status together with what the device said.
  /// Inputs: `feature`.
  /// Returns: `GenAiStatusReport`.
  /// Side effects: None.
  /// Notes: The detail is what makes a refusal actionable on a device that is
  /// not on a published support list; [statusOf] is the same answer without it.
  GenAiStatusReport reportOf(GenAiFeature feature) =>
      _status[feature] ?? GenAiStatusReport.unsupported;

  /// What AICore is installed on this device, once [refreshStatus] has asked.
  GenAiCoreInfo? get coreInfo => _coreInfo;

  /// Whether explanations can be generated right now.
  bool get canExplain =>
      _enabled && statusOf(GenAiFeature.prompt) == GenAiStatus.available;

  /// Whether a correction can be suggested right now.
  bool get canProofread =>
      _enabled && statusOf(GenAiFeature.proofread) == GenAiStatus.available;

  /// Whether the feature is on but at least one model still has to be fetched.
  bool get needsDownload =>
      _enabled &&
      !canExplain &&
      GenAiFeature.values.any(
        (f) =>
            statusOf(f) == GenAiStatus.downloadable ||
            statusOf(f) == GenAiStatus.downloading,
      );

  /// Purpose: Turn the feature on or off.
  /// Inputs: `value`.
  /// Returns: None.
  /// Side effects: Refreshes the statuses when switched on; cancels anything
  /// running when switched off.
  /// Notes: Switching off is immediate and total: nothing further is asked of
  /// the device, and the sentence lab stops offering the actions on its next
  /// build. Persisting the choice is `AppSettingsNotifier`'s job, as it is for
  /// every other preference.
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    if (value) {
      await refreshStatus();
    } else {
      await _backend.cancel();
      _status.clear();
      notifyListeners();
    }
  }

  /// Purpose: Ask the device what each feature can do.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Queries the platform; notifies listeners.
  /// Notes: Asked when the switch goes on, when Settings opens, and before
  /// every generation. The system can remove a model between two uses, and a
  /// remembered "available" would turn that into an error the learner cannot
  /// interpret.
  Future<void> refreshStatus() async {
    if (!platformMayHaveOnDeviceModel) {
      _status
        ..clear()
        ..addAll({
          for (final feature in GenAiFeature.values)
            feature: GenAiStatusReport.unsupported,
        });
      notifyListeners();
      return;
    }
    for (final feature in GenAiFeature.values) {
      _status[feature] = await _backend.statusReport(feature);
    }
    _coreInfo = await _backend.coreInfo();
    notifyListeners();
  }

  /// Purpose: Ask the system to fetch a feature's model.
  /// Inputs: `feature`.
  /// Returns: `Future<bool>` — whether the model is usable afterwards.
  /// Side effects: The **system** downloads a model over the network.
  /// Notes: Refused unless the learner turned the feature on, because this is
  /// the one action here that uses the network. Started only from the button
  /// in Settings, never on the learner's behalf.
  Future<bool> download(GenAiFeature feature) async {
    if (!_enabled || _busy) return false;
    _busy = true;
    _downloading = feature;
    _download = const GenAiDownload(bytes: 0, total: -1);
    notifyListeners();
    try {
      await _backend.download(
        feature,
        onProgress: (bytes, total) {
          _download = GenAiDownload(
            bytes: bytes,
            total: total > 0 ? total : (_download?.total ?? -1),
          );
          notifyListeners();
        },
      );
      _status[feature] = await _backend.statusReport(feature);
      return statusOf(feature) == GenAiStatus.available;
    } on GenAiException {
      _status[feature] = await _backend.statusReport(feature);
      return false;
    } finally {
      _busy = false;
      _downloading = null;
      _download = null;
      notifyListeners();
    }
  }

  /// Purpose: Generate one explanation.
  /// Inputs: The `prompt`.
  /// Returns: `Future<String>` — throws [GenAiException] instead of returning
  /// a failure.
  /// Side effects: Runs a model on the device.
  /// Notes: The gate order matters: off is refused before the status is even
  /// asked, so a device with a model present still does nothing while the
  /// switch is off. Nothing generated is stored anywhere.
  Future<String> explain(String prompt) async {
    _requireEnabled();
    if (_busy) throw const GenAiException(GenAiFailure.busy);
    _status[GenAiFeature.prompt] = await _backend.statusReport(
      GenAiFeature.prompt,
    );
    if (statusOf(GenAiFeature.prompt) != GenAiStatus.available) {
      notifyListeners();
      throw const GenAiException(GenAiFailure.unavailable);
    }
    _busy = true;
    notifyListeners();
    try {
      return await _backend
          .explain(prompt)
          .timeout(
            timeout,
            onTimeout: () => throw const GenAiException(GenAiFailure.timeout),
          );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Purpose: Ask for corrected versions of one short sentence.
  /// Inputs: `sentence`.
  /// Returns: `Future<List<String>>` — throws [GenAiException] on failure.
  /// Side effects: Runs a model on the device.
  /// Notes: Same gate order as [explain].
  Future<List<String>> proofread(String sentence) async {
    _requireEnabled();
    if (_busy) throw const GenAiException(GenAiFailure.busy);
    _status[GenAiFeature.proofread] = await _backend.statusReport(
      GenAiFeature.proofread,
    );
    if (statusOf(GenAiFeature.proofread) != GenAiStatus.available) {
      notifyListeners();
      throw const GenAiException(GenAiFailure.unavailable);
    }
    _busy = true;
    notifyListeners();
    try {
      return await _backend
          .proofread(sentence)
          .timeout(
            timeout,
            onTimeout: () => throw const GenAiException(GenAiFailure.timeout),
          );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Purpose: Stop whatever is running.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the platform request.
  /// Notes: Called when a page holding a pending result is disposed, so a
  /// model is not left running for an answer nobody will read.
  Future<void> cancel() async {
    if (!_busy) return;
    await _backend.cancel();
  }

  /// Purpose: Refuse every generating call while the feature is off.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Throws when the feature is off.
  /// Notes: Internal helper used within this file only. One place, called
  /// first in each generating method, so the rule cannot be half-applied.
  void _requireEnabled() {
    if (!_enabled) throw const GenAiException(GenAiFailure.unavailable);
  }
}

/// The AI assist service, read by Settings and the sentence lab.
///
/// A plain `Provider` rather than a `ChangeNotifierProvider` on purpose: this
/// is an app-wide singleton, and riverpod disposes the notifier a
/// `ChangeNotifierProvider` holds when the scope goes away — which would leave
/// the next `ProviderScope` (the next test, or a rebuilt root) holding a
/// disposed service. Consumers listen to it directly instead, the way the
/// speech services are listened to.
final aiAssistServiceProvider = Provider<AiAssistService>(
  (ref) => AiAssistService.instance,
);
