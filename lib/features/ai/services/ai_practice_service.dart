import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ai_assist_service.dart';
import 'genai_backend.dart';

/// Runs the practice tasks through the one model the device has.
///
/// There is a single on-device model and `AiAssistService` allows one
/// generation at a time, so two features that both want it have to take turns.
/// This is the turn-taking, and the rule is that **the learner's request wins**:
/// a background job — a question being written while the session runs — is
/// cancelled when an interactive one arrives, and retried afterwards.
///
/// Deliberately imports no storage and no progress provider. Nothing generated
/// here writes a record, and a test asserts that by reading this file's own
/// imports.
class AiPracticeService {
  /// Purpose: Create the practice service.
  /// Inputs: An `assist` service; the app-wide one by default.
  /// Returns: A new `AiPracticeService` instance.
  /// Side effects: None.
  /// Notes: None.
  AiPracticeService({AiAssistService? assist})
    : _assist = assist ?? AiAssistService.instance;

  /// The app-wide instance.
  static AiPracticeService instance = AiPracticeService();

  /// Purpose: Replace the instance in a test.
  /// Inputs: `service`.
  /// Returns: None.
  /// Side effects: Replaces the singleton.
  /// Notes: None.
  @visibleForTesting
  static void setInstanceForTest(AiPracticeService service) {
    instance = service;
  }

  /// How long a cancelled background job waits before trying again.
  static const retryDelay = Duration(seconds: 2);

  /// How many times a background job retries before giving up.
  static const maxRetries = 3;

  final AiAssistService _assist;
  Future<void>? _interactive;

  /// Whether the model is available to ask at all.
  bool get canRun => _assist.canExplain;

  /// Purpose: Run one prompt the learner is waiting for.
  /// Inputs: The `prompt`, and `maxOutputTokens` — the budget from the prompt
  /// asset, so a task that needs a longer answer can say so.
  /// Returns: `Future<String>` — throws [GenAiException] on failure.
  /// Side effects: Runs a model on the device.
  /// Notes: Interactive requests queue behind each other rather than failing
  /// with "busy": a learner who taps two buttons quickly should get two
  /// answers, not an error. Background jobs get out of the way instead.
  Future<String> run(String prompt, {int? maxOutputTokens}) {
    final previous = _interactive;
    final completer = Completer<String>();
    _interactive = completer.future.then((_) {}, onError: (_) {});
    Future<void>(() async {
      if (previous != null) await previous;
      try {
        completer.complete(
          await _assist.explain(prompt, maxOutputTokens: maxOutputTokens),
        );
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  /// Purpose: Run one prompt nobody is waiting for.
  /// Inputs: The `prompt`, and `maxOutputTokens`.
  /// Returns: `Future<String?>` — null when it never got a turn.
  /// Side effects: Runs a model on the device, possibly after a wait.
  /// Notes: Yields to interactive work. If the model is busy, this waits and
  /// tries again a few times, and gives up quietly rather than surfacing an
  /// error — nothing is waiting for it, so there is nobody to tell.
  Future<String?> runInBackground(String prompt, {int? maxOutputTokens}) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final interactive = _interactive;
      if (interactive != null) await interactive;
      try {
        return await _assist.explain(prompt, maxOutputTokens: maxOutputTokens);
      } on GenAiException catch (error) {
        if (error.failure != GenAiFailure.busy) return null;
        await Future<void>.delayed(retryDelay);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
