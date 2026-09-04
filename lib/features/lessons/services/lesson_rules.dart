/// What a unit's state is, and when the next one opens.
///
/// Pure functions over the progress file and the path. Nothing here reads
/// storage or builds a widget, so the rules can be read in one sitting and
/// tested without a device.
library;

import '../../progress/models/study_record.dart';
import '../models/lesson_path.dart';

/// How many questions an ordinary practice session asks.
const unitSessionSize = 12;

/// How many a checkpoint asks. Longer, because it decides something.
const checkpointSize = 20;

/// The first-try accuracy a checkpoint has to reach.
///
/// Seven in ten. High enough that passing means something, low enough that a
/// learner who has understood the unit is not sent back by two slips.
const checkpointPassAccuracy = 0.7;

/// Where a unit stands for one learner.
enum UnitState {
  /// The previous unit's checkpoint has not been passed.
  ///
  /// Its practice is closed, but **its checkpoint is not** — see
  /// [unitState] for why.
  locked,

  /// Open, and not yet passed.
  open,

  /// Its checkpoint has been passed.
  passed,
}

/// Purpose: Name the record a unit's checkpoint result is written to.
/// Inputs: The unit `id`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: `lesson:` rather than `unit:` because that prefix is what
/// `studyKindOf` already recognises, and the id inside it is the unit's own —
/// so a record survives a unit being reordered but not renamed.
String lessonRecordId(String unitId) =>
    'lesson:${unitId.startsWith('unit:') ? unitId.substring(5) : unitId}';

/// Purpose: Decide where each unit of a path stands.
/// Inputs: The `path` and the learner's `progress`.
/// Returns: `Map<String, UnitState>` keyed by unit id.
/// Side effects: None.
/// Notes: The first unit is always open. After that a unit opens when the one
/// before it has been passed. **A locked unit's checkpoint is still
/// available** — that is what [canAttemptCheckpoint] says — because a learner
/// who already knows this material should not have to grind through six units
/// to prove it, and because the only thing a checkpoint can do is unlock what
/// the learner has demonstrated.
Map<String, UnitState> unitStates(LessonPath path, ProgressData progress) {
  final passed = <String>{
    for (final record in progress.records)
      if (record.correct > 0 && record.id.startsWith('lesson:')) record.id,
  };
  final out = <String, UnitState>{};
  var previousPassed = true;
  for (final unit in path.units) {
    final isPassed = passed.contains(lessonRecordId(unit.id));
    out[unit.id] = isPassed
        ? UnitState.passed
        : previousPassed
        ? UnitState.open
        : UnitState.locked;
    previousPassed = isPassed;
  }
  return out;
}

/// Purpose: Say whether a unit's checkpoint may be attempted.
/// Inputs: The unit's `state`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Always true. It is a function rather than a constant because the
/// rule is worth naming: a checkpoint is how a learner skips ahead, and
/// hiding it behind the units it would let them skip is circular.
bool canAttemptCheckpoint(UnitState state) => true;

/// Purpose: Measure how much of a unit the learner has answered correctly.
/// Inputs: The `unit` and the learner's `progress`.
/// Returns: `double` between 0 and 1.
/// Side effects: None.
/// Notes: Derived from the item records, never stored: the fraction of the
/// unit's items that have been answered right at least once. That is a
/// coarser measure than the scheduler's, and deliberately so — a progress bar
/// that went backwards because an interval lapsed would punish the learner
/// for the passage of time.
double unitProgress(LessonUnit unit, ProgressData progress) {
  final items = unit.items;
  if (items.isEmpty) return 0;
  final known = <String>{
    for (final record in progress.records)
      if (record.correct > 0) record.id,
  };
  var done = 0;
  for (final item in items) {
    if (known.contains(item)) done++;
  }
  return done / items.length;
}

/// Purpose: Find the unit a learner should open next.
/// Inputs: The `path` and the `states` from [unitStates].
/// Returns: `LessonUnit?` — null when every unit has been passed.
/// Side effects: None.
/// Notes: The first open unit, which is the first one not passed. There is no
/// cleverer answer: the path is an order, and the point of an order is that
/// the next thing is the next thing.
LessonUnit? nextUnit(LessonPath path, Map<String, UnitState> states) {
  for (final unit in path.units) {
    if (states[unit.id] == UnitState.open) return unit;
  }
  return null;
}
