import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapps_ai/myapps_ai.dart' show AiExecutionGate;

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
  bool _preferFast = false;
  GenAiDownload? _download;
  GenAiFeature? _downloading;
  final _execution = AiExecutionGate();

  /// Whether the learner turned on-device AI on. Off until they do.
  bool get enabled => _enabled;

  /// Whether a generation or a download is running.
  bool get busy => _execution.busy || _downloading != null;

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

  /// Whether the smaller, faster model is preferred where a device serves both.
  ///
  /// Only meaningful on a device that serves more than one size; everywhere
  /// else the probe finds the same single variant either way.
  bool get preferFast => _preferFast;

  /// Purpose: Choose the larger or the faster model, and re-probe.
  /// Inputs: `value` — true for the faster model.
  /// Returns: None.
  /// Side effects: Re-probes the device; notifies listeners.
  /// Notes: A full re-probe rather than a stored preference applied later: the
  /// point of the switch is to change which model is serving now, and a
  /// preference that takes effect at the next launch is one the learner cannot
  /// verify. Persisting the choice is `AppSettingsNotifier`'s job, as it is for
  /// every other preference.
  Future<void> setPreferFast(bool value) async {
    if (_preferFast == value) return;
    _execution.invalidate();
    if (busy) await _backend.cancel();
    _preferFast = value;
    if (_enabled) {
      await refreshStatus();
    } else {
      notifyListeners();
    }
  }

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
    _execution.invalidate();
    _enabled = value;
    notifyListeners();
    if (value) {
      await refreshStatus();
    } else {
      await _backend.cancel();
      _status.clear();
      _coreInfo = null;
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
    if (!_enabled) return;
    final epoch = _execution.generation;
    if (!platformMayHaveOnDeviceModel &&
        _backend is! MethodChannelGenAiBackend) {
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
      // Forced: this is the deliberate refresh — Settings opening, the switch
      // going on, the Check again button — and it is the only path that probes
      // every model variant rather than trusting the one already serving.
      final report = await _backend.statusReport(
        feature,
        force: true,
        preferFast: _preferFast,
      );
      if (!_enabled || epoch != _execution.generation) return;
      _status[feature] = report;
    }
    final info = await _backend.coreInfo();
    if (!_enabled || epoch != _execution.generation) return;
    _coreInfo = info;
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
    if (!_enabled || busy) return false;
    final epoch = _execution.generation;
    _downloading = feature;
    _download = const GenAiDownload(bytes: 0, total: -1);
    notifyListeners();
    try {
      await _backend.download(
        feature,
        onProgress: (bytes, total) {
          if (!_enabled || epoch != _execution.generation) return;
          _download = GenAiDownload(
            bytes: bytes,
            total: total > 0 ? total : (_download?.total ?? -1),
          );
          notifyListeners();
        },
      );
      if (!_enabled || epoch != _execution.generation) return false;
      final report = await _backend.statusReport(feature);
      if (!_enabled || epoch != _execution.generation) return false;
      _status[feature] = report;
      return statusOf(feature) == GenAiStatus.available;
    } on GenAiException {
      if (_enabled && epoch == _execution.generation) {
        final report = await _backend.statusReport(feature);
        if (_enabled && epoch == _execution.generation) {
          _status[feature] = report;
        }
      }
      return false;
    } finally {
      _downloading = null;
      _download = null;
      notifyListeners();
    }
  }

  /// Purpose: Generate one explanation.
  /// Inputs: The `prompt`, and `maxOutputTokens` — how long the answer may
  /// be, from the prompt asset rather than from here.
  /// Returns: `Future<String>` — throws [GenAiException] instead of returning
  /// a failure.
  /// Side effects: Runs a model on the device.
  /// Notes: The gate order matters: off is refused before the status is even
  /// asked, so a device with a model present still does nothing while the
  /// switch is off. The busy flag is taken before the status is awaited, so a
  /// second call arriving meanwhile is refused as busy. Nothing generated is
  /// stored anywhere.
  Future<String> explain(String prompt, {int? maxOutputTokens}) async {
    return _run(
      GenAiFeature.prompt,
      () => _backend.explain(
        prompt,
        maxOutputTokens: maxOutputTokens ?? defaultMaxOutputTokens,
      ),
    );
  }

  /// Purpose: Execute one capability through shared gate. Inputs: feature, operation.
  /// Returns: Result. Side effects: Queries and invokes backend. Notes: No persistence.
  Future<T> _run<T>(GenAiFeature feature, Future<T> Function() operation) {
    _requireEnabled();
    if (_downloading != null) throw const GenAiException(GenAiFailure.busy);
    return _execution.run<T>(
      enabled: () => _enabled,
      unavailable: () => const GenAiException(GenAiFailure.unavailable),
      occupied: () => const GenAiException(GenAiFailure.busy),
      cancelled: () => const GenAiException(GenAiFailure.cancelled),
      timedOut: () => const GenAiException(GenAiFailure.timeout),
      cancel: _backend.cancel,
      timeout: timeout,
      changed: notifyListeners,
      body: (current) async {
        final report = await _backend.statusReport(
          feature,
          preferFast: _preferFast,
        );
        if (!current()) throw const GenAiException(GenAiFailure.cancelled);
        _status[feature] = report;
        if (report.status != GenAiStatus.available) {
          throw const GenAiException(GenAiFailure.unavailable);
        }
        return operation();
      },
    );
  }

  /// How long an answer may be when the caller names no limit.
  ///
  /// The prompt asset carries the real budget per task; this is the floor for
  /// a caller that has no asset loaded, and matches what the platform side
  /// used to assume.
  static const defaultMaxOutputTokens = 256;

  /// Purpose: Ask for corrected versions of one short sentence.
  /// Inputs: `sentence`.
  /// Returns: `Future<List<String>>` — throws [GenAiException] on failure.
  /// Side effects: Runs a model on the device.
  /// Notes: Same gate order as [explain].
  Future<List<String>> proofread(String sentence) async {
    return _run(GenAiFeature.proofread, () => _backend.proofread(sentence));
  }

  /// Purpose: Stop whatever is running.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels the platform request.
  /// Notes: Called when a page holding a pending result is disposed, so a
  /// model is not left running for an answer nobody will read.
  Future<void> cancel() async {
    if (!busy) return;
    _execution.invalidate();
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
