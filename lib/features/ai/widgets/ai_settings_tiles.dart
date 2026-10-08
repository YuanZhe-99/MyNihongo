import 'package:flutter/material.dart';
import 'package:myapps_ai_ui/myapps_ai_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../services/ai_assist_service.dart';
import '../services/genai_backend.dart';
import 'ai_source_controls.dart';

/// The Settings rows that configure on-device AI assistance.
///
/// The section is built the same way the Speech one is: a master switch that
/// is off until the learner turns it on, then a status row per feature. The
/// two features have separate models and separate downloads, so neither hides
/// the other — a device can end up with explanations and no proofreading.
///
/// The download note is not a footnote. Downloading a model is the only thing
/// this feature does over the network, it is done by the system rather than by
/// the app, and it happens only when the learner taps the button. Saying all
/// three where the button is is what makes the switch an informed one.
class AiSettingsTiles extends ConsumerStatefulWidget {
  const AiSettingsTiles({super.key});

  @override
  ConsumerState<AiSettingsTiles> createState() => _AiSettingsTilesState();
}

class _AiSettingsTilesState extends ConsumerState<AiSettingsTiles> {
  /// Purpose: Follow the service, and ask what its models can do.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Subscribes to the service; queries AICore, but only when
  /// the feature is already on.
  /// Notes: Nothing is asked of the device while the switch is off — opening
  /// Settings on a phone whose owner never turned this on touches no model.
  /// The service is listened to directly rather than watched through riverpod,
  /// because it is an app-wide singleton; see `aiAssistServiceProvider`.
  @override
  void initState() {
    super.initState();
    final service = AiAssistService.instance;
    service.addListener(_onServiceChanged);
    if (service.enabled) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => service.refreshStatus(),
      );
    }
  }

  /// Purpose: Stop following the service.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Removes the listener.
  /// Notes: The service outlives this widget, so the listener has to go.
  @override
  void dispose() {
    AiAssistService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  /// Purpose: Rebuild when a status or a download changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds.
  /// Notes: Internal helper used within this file only.
  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  /// Purpose: Return the app's current locale as a tag such as `zh_TW`.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _localeTag() {
    final l = Localizations.localeOf(context);
    return l.countryCode == null
        ? l.languageCode
        : '${l.languageCode}_${l.countryCode}';
  }

  /// Purpose: Build the AI settings rows.
  /// Inputs: The build `context`.
  /// Returns: `Widget` — the switch, then one row per feature.
  /// Side effects: None until a control is used.
  /// Notes: On a platform with no on-device model the section is one
  /// explanatory line rather than a switch: offering a control that cannot do
  /// anything is worse than saying why there is none. `settings_page.dart`
  /// leaves the whole section out there; this line is the safety net for any
  /// other caller.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final service = ref.watch(aiAssistServiceProvider);

    return MyAppsAiSettingsSkeleton(
      enabled: settings.aiAssistEnabled,
      master: MyAppsAiPreference(
        title: l10n.aiEnable,
        description: l10n.aiEnableBody,
        isThreeLine: true,
        value: settings.aiAssistEnabled,
        onChanged: notifier.setAiAssistEnabled,
      ),
      source: [
        AiSourceControls(
          backend: MethodChannelGenAiBackend.sourceBackend,
          onSelected: (id) async {
            final backend = MethodChannelGenAiBackend.sourceBackend;
            if (id == backend.selection.global) return;
            await service.setEnabled(false);
            await backend.select(id);
            await service.setEnabled(settings.aiAssistEnabled);
          },
        ),
        if (MethodChannelGenAiBackend.hasSizeChoice(
          service.reportOf(GenAiFeature.prompt).served,
        ))
          MyAppsAiPreference(
            icon: Icons.speed_outlined,
            title: l10n.aiPreferFast,
            description: l10n.aiPreferFastBody,
            value: settings.preferFastModel,
            onChanged: service.busy ? null : notifier.setPreferFastModel,
          ),
      ],
      features: [
        _featureRow(
          context,
          service,
          GenAiFeature.prompt,
          l10n.aiStatusPrompt,
          debug: settings.debugMode,
        ),
        _featureRow(
          context,
          service,
          GenAiFeature.proofread,
          l10n.aiStatusProofread,
          debug: settings.debugMode,
        ),
        // Only where the device actually served both sizes. A device that
        // serves one — the Galaxy Z Fold 8 serves the faster model and
        // refuses the larger one — gets no control, because a switch that
        // cannot change what is serving teaches the learner to distrust the
        // page.
        MyAppsAiModelNotes(
          downloadNote: l10n.aiDownloadNote,
          storageNote: l10n.aiModelStorageNote,
          diagnostic: settings.debugMode
              ? _coreLine(l10n, service.coreInfo)
              : null,
        ),
      ],
      diagnostics: settings.debugMode
          ? MyAppsAiDiagnosticsView(
              load: () => MethodChannelGenAiBackend.sourceBackend.diagnostics(
                localeTag: _localeTag(),
              ),
              labels: AiDiagnosticsLabels(
                title: l10n.aiTechnicalDetails,
                copy: l10n.aiDiagnosticsCopy,
                copied: l10n.aiDiagnosticsCopied,
                notIncluded: l10n.aiDiagnosticsNotIncluded,
              ),
            )
          : null,
    );
  }

  /// Purpose: Build one feature's status row.
  /// Inputs: `context`, the `service`, the `feature` and its `label`.
  /// Returns: `Widget`.
  /// Side effects: None until the Download button is used.
  /// Notes: Internal helper used within this file only. The Download button
  /// appears only for a feature the system says it can fetch, and it is
  /// disabled while anything else is downloading, because AICore serves one at
  /// a time and two spinners would imply otherwise.
  Widget _featureRow(
    BuildContext context,
    AiAssistService service,
    GenAiFeature feature,
    String label, {
    required bool debug,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final status = service.statusOf(feature);
    final downloadingThis = service.downloadingFeature == feature;
    final progress = service.downloadProgress;

    // Only where somebody has asked for it. The line names a model variant and
    // a token limit; a learner can act on neither, and "Ready" is the whole of
    // what they need. Behind the flag it is still the first thing a bug report
    // needs, which is why it has not been deleted.
    final detail = debug
        ? _diagnostic(status, service.reportOf(feature))
        : null;

    return MyAppsAiCapabilityTile(
      icon: _iconFor(status),
      title: label,
      statusText: downloadingThis
          ? _progressLabel(l10n, progress)
          : _statusLabel(l10n, status, debug: debug),
      diagnostic: detail,
      action: switch (status) {
        GenAiStatus.downloadable => FilledButton.tonal(
          onPressed: service.busy ? null : () => service.download(feature),
          child: Text(l10n.aiDownload),
        ),
        // Availability changes without the app doing anything: AICore
        // provisions itself after setup, and sometimes only after a restart.
        // Without this the only way to re-ask was to toggle the switch.
        GenAiStatus.unavailable ||
        GenAiStatus.unreachable ||
        GenAiStatus.unknown => IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.aiCheckAgain,
          onPressed: service.busy ? null : () => service.refreshStatus(),
        ),
        GenAiStatus.downloading || GenAiStatus.available || _ =>
          downloadingThis
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
      },
    );
  }

  /// Purpose: Name a status in the learner's language.
  /// Inputs: `l10n`, `status`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. `unsupported` and
  /// `unavailable` share a line: from where the learner stands, a platform
  /// with no AICore and a device AICore will not serve are the same fact.
  static String _statusLabel(
    AppLocalizations l10n,
    GenAiStatus status, {
    bool debug = false,
  }) => switch (status) {
    GenAiStatus.available => l10n.aiStatusAvailable,
    GenAiStatus.downloadable => l10n.aiStatusDownloadable,
    GenAiStatus.downloading => l10n.aiStatusDownloading,
    GenAiStatus.unavailable => l10n.aiStatusUnavailable,
    // A learner cannot act on "a status this version does not recognise"
    // any differently from "not available", and the distinction only means
    // something to whoever has to work out why. It stays separate behind
    // the flag, because reading an unknown status as a refusal is exactly
    // the class of mistake that produced two wrong diagnoses.
    GenAiStatus.unknown =>
      debug ? l10n.aiStatusUnknown : l10n.aiStatusUnavailable,
    GenAiStatus.unsupported => l10n.aiStatusUnavailable,
    GenAiStatus.unreachable => l10n.aiStatusUnreachable,
  };

  /// Purpose: Build the untranslated diagnostic line under a feature.
  /// Inputs: `status` and its `report`.
  /// Returns: `String?` — null when there is nothing worth showing.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A working feature
  /// names the variant and the model that serve it, because "Ready" alone
  /// does not say *what* is ready and the answer differs per device. A
  /// refused one carries the raw status and every variant that was tried,
  /// which is the line two wrong diagnoses were missing.
  static String? _diagnostic(GenAiStatus status, GenAiStatusReport report) {
    if (status == GenAiStatus.available) {
      final parts = [
        ?report.variant,
        ?report.baseModelName,
        if (report.tokenLimit case final limit?) '$limit tok',
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    return report.detail;
  }

  /// Purpose: Name the AICore installation behind these features.
  /// Inputs: `l10n`, `info` — null before the device has been asked.
  /// Returns: `String?` — null when there is nothing to say.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The device model rides
  /// along because the published support lists are per device, and "which
  /// phone is this" is the first thing a report about them has to answer.
  static String? _coreLine(AppLocalizations l10n, GenAiCoreInfo? info) {
    if (info == null) return null;
    if (!info.installed) return l10n.aiCoreMissing;
    final version = info.versionName;
    final device = info.device;
    return [
      if (version != null) l10n.aiCoreVersion(version),
      ?device,
      // Only when ML Kit could actually be asked. On a device that refuses
      // every model variant this is the line that says whether AICore itself
      // is the problem, and nothing else in the app can answer that.
      if (info.compatible case final ok?)
        ok ? l10n.aiCoreCompatible : l10n.aiCoreIncompatible,
    ].join(' · ');
  }

  /// Purpose: Say how far a download has got.
  /// Inputs: `l10n`, `progress`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Megabytes rather than
  /// a percentage, because the system does not always report a total and a
  /// percentage that cannot be computed would have to be hidden halfway
  /// through — a number that only grows is honest either way.
  static String _progressLabel(AppLocalizations l10n, GenAiDownload? progress) {
    if (progress == null || progress.bytes <= 0) return l10n.aiDownloading;
    final megabytes = (progress.bytes / (1024 * 1024)).toStringAsFixed(1);
    return l10n.aiDownloadedBytes(megabytes);
  }

  /// Purpose: Pick the icon for a status.
  /// Inputs: `status`.
  /// Returns: `IconData`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The icon repeats what
  /// the subtitle says; it never carries the meaning on its own.
  static IconData _iconFor(GenAiStatus status) => switch (status) {
    GenAiStatus.available => Icons.check_circle_outline,
    GenAiStatus.downloadable => Icons.cloud_download_outlined,
    GenAiStatus.downloading => Icons.downloading_outlined,
    GenAiStatus.unknown => Icons.help_outline,
    _ => Icons.block_outlined,
  };
}
