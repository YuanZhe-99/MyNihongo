import 'token.dart';

/// One bunsetsu: a content word plus whatever attached to it.
///
/// Japanese dependency is described between these, not between words, because
/// a particle belongs to the word before it and moves with it.
class Bunsetsu {
  const Bunsetsu({
    required this.first,
    required this.last,
    required this.head,
    required this.isPredicate,
    this.dependsOn,
    this.marker,
    this.forms = const [],
  });

  /// Index of the first token, into `SentenceAnalysis.tokens`.
  final int first;

  /// Index of the last token, inclusive.
  final int last;

  /// Index of the content token this chunk is about.
  final int head;

  /// Index of the chunk this one attaches to; null for the clause root.
  final int? dependsOn;

  /// The last particle in the chunk, which is what decided the attachment.
  final String? marker;

  /// Whether this chunk can govern others.
  final bool isPredicate;

  /// The forms carried by the head and everything after it.
  final List<InflectionForm> forms;
}

/// A taught grammar point found in the sentence.
class GrammarMatch {
  const GrammarMatch({
    required this.pointId,
    required this.first,
    required this.last,
  });

  /// The `grammar:` id, so the UI can open the point.
  final String pointId;

  /// First token index of the match.
  final int first;

  /// Last token index, inclusive.
  final int last;

  /// How many tokens the match covers, for resolving overlaps.
  int get span => last - first + 1;
}

/// The kinds of problem the checks can raise.
///
/// Every one is reported as a **possible** issue. The analyser has no model of
/// what the writer meant, so it can only say that something looks unusual —
/// and a learner told they are wrong when they are not stops trusting the tool.
enum IssueKind {
  /// An を-marked phrase on a verb the catalog tags intransitive only.
  particleFrame,

  /// An adjective given a verb ending: 高いません for 高くないです.
  adjectiveAsVerb,

  /// な where の belongs, or the reverse.
  naNoConfusion,

  /// A past time word with a non-past predicate, or the reverse.
  tenseTimeWord,

  /// A clause that ends on a noun with nothing to predicate it.
  missingCopula,
}

/// One possible issue, located in the sentence.
class Issue {
  const Issue({
    required this.kind,
    required this.first,
    required this.last,
    this.detail,
    this.suggestion,
  });

  /// Which check raised it.
  final IssueKind kind;

  /// First token index the issue covers.
  final int first;

  /// Last token index, inclusive.
  final int last;

  /// The word the message names, when it names one.
  final String? detail;

  /// What to write instead, when the check can say.
  final String? suggestion;
}

/// Everything the analyser found in one sentence.
class SentenceAnalysis {
  const SentenceAnalysis({
    required this.input,
    required this.normalized,
    required this.tokens,
    required this.chunks,
    required this.grammar,
    required this.issues,
  });

  /// What the learner typed.
  final String input;

  /// The same text after normalization, which token offsets are into.
  final String normalized;

  /// Every token, in order.
  final List<Token> tokens;

  /// Every bunsetsu, in order.
  final List<Bunsetsu> chunks;

  /// The taught grammar points found, longest span first.
  final List<GrammarMatch> grammar;

  /// Possible issues, in token order.
  final List<Issue> issues;

  /// Whether anything at all could not be read.
  bool get hasUnknown => tokens.any((t) => t.category == TokenCategory.unknown);

  /// Purpose: Render the analysis as one line, for fixture comparison.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: The fixture format is deliberately readable rather than compact:
  /// the way these are authored is by recording them and reading the diff, so
  /// a wrong parse has to be visible at a glance. Four fields separated by
  /// ` | `: tokens, chunk dependencies, grammar ids, issue kinds.
  String toFixtureString() {
    final tokenPart = tokens.map((t) => t.toString()).join(' ');
    final chunkPart = chunks
        .map((c) {
          final surface = tokens
              .sublist(c.first, c.last + 1)
              .map((t) => t.surface)
              .join();
          return '[$surface→${c.dependsOn ?? 'root'}]';
        })
        .join(' ');
    final grammarPart = grammar.isEmpty
        ? '-'
        : grammar.map((g) => g.pointId).join(' ');
    final issuePart = issues.isEmpty
        ? '-'
        : issues.map((i) => i.kind.name).join(' ');
    return '$tokenPart | $chunkPart | $grammarPart | $issuePart';
  }
}

/// The seam an on-device model would plug into, if one is ever added.
///
/// `PLAN.md` M2.3 keeps AICore / Gemini Nano as an **optional enhancement**
/// that never becomes the source of truth: the analysis above is deterministic
/// and testable, and anything a model adds is labelled as generated. Nothing
/// implements this yet — it is here so the shape is decided before the
/// pressure to add one exists, and so `SentenceAnalyzer` has somewhere to put
/// it that is not the middle of the pipeline.
abstract class SentenceEnhancer {
  /// Purpose: Report whether an on-device model is present and enabled.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: May query a platform capability.
  /// Notes: Must be false on every device without one, and false by default
  /// even on devices with one.
  Future<bool> isAvailable();

  /// Purpose: Explain one issue, or the sentence, in more words.
  /// Inputs: The `analysis`, an optional `issue` to focus on, and the UI
  /// `locale`.
  /// Returns: `Future<String?>` — null when nothing could be generated.
  /// Side effects: Runs a model on the device.
  /// Notes: Whatever comes back is labelled as generated and never replaces a
  /// deterministic result.
  Future<String?> explain(
    SentenceAnalysis analysis,
    Issue? issue,
    String locale,
  );
}
