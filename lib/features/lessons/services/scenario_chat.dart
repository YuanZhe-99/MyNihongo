/// One turn of a free conversation at the end of a scenario.
///
/// Either the learner's own line or the other speaker's reply. The learner's
/// may carry what the proofreader made of it; the reply may carry a
/// translation. Nothing here is ever written to disk — see [ScenarioChat].
class ScenarioTurn {
  /// Purpose: Hold one turn.
  /// Inputs: Whether it is the `learner`'s, the `ja` said, and optionally the
  /// `meaning` of a reply or the `proofread` form of a learner line.
  /// Returns: A new `ScenarioTurn` instance.
  /// Side effects: None.
  /// Notes: None.
  const ScenarioTurn({
    required this.learner,
    required this.ja,
    this.meaning,
    this.proofread,
  });

  /// Whether the learner said this, rather than the other speaker.
  final bool learner;

  /// What was said.
  final String ja;

  /// What it means, for a reply the model translated.
  final String? meaning;

  /// What the proofreader would have written instead, when it had something to
  /// say and the learner's line is the one being shown.
  final String? proofread;
}

/// The free conversation that follows a scenario's script.
///
/// Deliberately a plain object with no storage and no notifier: the scenario
/// page has written nothing to disk since it was built, and a chat line out of
/// its situation is not a piece of writing anybody would re-open. When the page
/// closes, this goes with it.
///
/// The cap exists because a model answering in character has no reason to stop.
/// Eight turns is long enough to be a conversation and short enough to end
/// while the learner still means to be having one — and [end] is always
/// available before that, because the learner deciding when they are done is
/// the difference between a conversation and an exercise.
class ScenarioChat {
  /// How many turns the learner may take before the conversation is closed.
  static const maxLearnerTurns = 8;

  final List<ScenarioTurn> _turns = [];
  bool _ended = false;

  /// Everything said so far, oldest first.
  List<ScenarioTurn> get turns => List.unmodifiable(_turns);

  /// How many turns the learner has taken.
  int get learnerTurns => _turns.where((turn) => turn.learner).length;

  /// Whether the learner has used every turn.
  bool get capReached => learnerTurns >= maxLearnerTurns;

  /// Whether the learner closed the conversation themselves.
  bool get ended => _ended;

  /// Whether anything has been said yet.
  bool get isEmpty => _turns.isEmpty;

  /// Purpose: Record what the learner said.
  /// Inputs: The `ja` they typed and, where the proofreader had something to
  /// say, the `proofread` form.
  /// Returns: None.
  /// Side effects: Appends a turn.
  /// Notes: Recorded before the reply is asked for, so the learner sees their
  /// own line in the transcript while the model is still writing.
  void addLearner(String ja, {String? proofread}) {
    _turns.add(ScenarioTurn(learner: true, ja: ja, proofread: proofread));
  }

  /// Purpose: Record what the other speaker said back.
  /// Inputs: The reply's `ja` and its `meaning` where there is one.
  /// Returns: None.
  /// Side effects: Appends a turn.
  /// Notes: None.
  void addReply(String ja, {String? meaning}) {
    _turns.add(ScenarioTurn(learner: false, ja: ja, meaning: meaning));
  }

  /// Purpose: Close the conversation.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Marks it ended and drops what was said.
  /// Notes: The turns are cleared because nothing here was ever going to be
  /// kept: leaving them on screen after the learner has said they are done
  /// would suggest they were.
  void end() {
    _ended = true;
    _turns.clear();
  }
}
