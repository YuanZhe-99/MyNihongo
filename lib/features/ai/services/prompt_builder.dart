import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../content/models/content_catalog.dart';
import '../../content/models/localized_strings.dart';
import '../../sentence/models/sentence_analysis.dart';
import '../../sentence/models/token.dart';

/// The versioned prompt templates, loaded from
/// `assets/content/prompts/sentence_explain.json`.
///
/// The prompts are a content asset rather than string literals for the reason
/// every other content file is one: a change to what the model is asked
/// changes what the learner reads, and it should be reviewable as a diff of
/// data rather than buried in code. They are **not** in the ARB files: nothing
/// here is ever rendered — it is sent to a model.
@immutable
class PromptTemplates {
  const PromptTemplates({
    required this.schemaVersion,
    required this.limits,
    required this.labels,
    required this.tasks,
  });

  /// The template file's schema version.
  final int schemaVersion;

  /// The named length and count caps the builder enforces.
  final Map<String, int> limits;

  /// Field labels, by language code then field name.
  final Map<String, Map<String, String>> labels;

  /// Instruction and rules, by task then language code.
  final Map<String, Map<String, PromptTask>> tasks;

  /// An empty set, used when the asset cannot be read.
  static const empty = PromptTemplates(
    schemaVersion: 0,
    limits: {},
    labels: {},
    tasks: {},
  );

  /// Purpose: Look up a named cap, with the fallback the code was written for.
  /// Inputs: `name`, `fallback`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: A missing or nonsensical value falls back rather than throwing:
  /// the caps exist to keep a request inside the API's limits, so a broken
  /// asset must not be able to remove one.
  int limit(String name, int fallback) {
    final value = limits[name];
    return value != null && value > 0 ? value : fallback;
  }

  /// Purpose: Parse the template file.
  /// Inputs: Decoded `json`.
  /// Returns: `PromptTemplates`.
  /// Side effects: None.
  /// Notes: Tolerant by design — an unreadable section yields an empty one,
  /// and `PromptBuilder` treats an empty template as "no AI available" rather
  /// than sending a prompt with no instructions in it.
  factory PromptTemplates.fromJson(Object? json) {
    if (json is! Map) return empty;
    final limits = <String, int>{};
    final rawLimits = json['limits'];
    if (rawLimits is Map) {
      rawLimits.forEach((key, value) {
        if (key is String && value is int) limits[key] = value;
      });
    }
    final labels = <String, Map<String, String>>{};
    final rawLabels = json['labels'];
    if (rawLabels is Map) {
      rawLabels.forEach((language, fields) {
        if (language is! String || fields is! Map) return;
        final parsed = <String, String>{};
        fields.forEach((name, text) {
          if (name is String && text is String) parsed[name] = text;
        });
        labels[language] = parsed;
      });
    }
    final tasks = <String, Map<String, PromptTask>>{};
    final rawTasks = json['tasks'];
    if (rawTasks is Map) {
      rawTasks.forEach((task, languages) {
        if (task is! String || languages is! Map) return;
        final parsed = <String, PromptTask>{};
        languages.forEach((language, body) {
          if (language is! String || body is! Map) return;
          final instruction = body['instruction'];
          if (instruction is! String) return;
          parsed[language] = PromptTask(
            instruction: instruction,
            rules: [
              if (body['rules'] is List)
                for (final rule in body['rules'] as List)
                  if (rule is String) rule,
            ],
          );
        });
        tasks[task] = parsed;
      });
    }
    return PromptTemplates(
      schemaVersion: json['schemaVersion'] is int
          ? json['schemaVersion'] as int
          : 0,
      limits: limits,
      labels: labels,
      tasks: tasks,
    );
  }
}

/// One task's instruction and its rules, in one language.
@immutable
class PromptTask {
  const PromptTask({required this.instruction, required this.rules});

  final String instruction;
  final List<String> rules;
}

/// Builds the text sent to the on-device model.
///
/// Every prompt is grounded in what the deterministic pipeline already found:
/// the tokens it produced, the issue message **as the app words it**, and the
/// catalog's own explanation of each grammar point the sentence matched. The
/// model is asked to explain that analysis, never to produce one — which is
/// what keeps the answer consistent with the rest of the page, and what
/// `AGENTS.md` means by generated text never replacing a deterministic result.
class PromptBuilder {
  const PromptBuilder(this.templates);

  /// The loaded templates.
  final PromptTemplates templates;

  /// Purpose: Build the prompt asking about one flagged issue.
  /// Inputs: The `analysis`, the `issue`, its already-worded `message`, the
  /// `catalog` for grammar explanations, and the UI `locale`.
  /// Returns: `String?` — null when the templates are missing.
  /// Side effects: None.
  /// Notes: `message` is passed in rather than re-derived because it is the
  /// sentence the learner is looking at; asking the model about a differently
  /// worded issue would produce an answer that does not match the screen.
  String? forIssue(
    SentenceAnalysis analysis,
    Issue issue,
    String message,
    ContentCatalog? catalog,
    Locale locale,
  ) {
    return _build(
      task: 'issue',
      locale: locale,
      analysis: analysis,
      catalog: catalog,
      note: '${_span(analysis, issue.first, issue.last)} — $message',
    );
  }

  /// Purpose: Build the prompt asking about the sentence as a whole.
  /// Inputs: The `analysis`, the `catalog`, and the UI `locale`.
  /// Returns: `String?` — null when the templates are missing.
  /// Side effects: None.
  /// Notes: None.
  String? forSentence(
    SentenceAnalysis analysis,
    ContentCatalog? catalog,
    Locale locale,
  ) {
    return _build(
      task: 'sentence',
      locale: locale,
      analysis: analysis,
      catalog: catalog,
      note: null,
    );
  }

  /// Purpose: Prepare a sentence for the proofreading model.
  /// Inputs: `sentence`.
  /// Returns: `String?` — null when it is empty or too long to send.
  /// Side effects: None.
  /// Notes: Too long is a **refusal, not a truncation**: proofreading half a
  /// sentence would suggest a correction for a sentence the learner never
  /// wrote. The cap is characters against an API limit of 256 tokens, chosen
  /// low because Japanese tokenizes to more tokens per character than English.
  String? forProofreading(String sentence) {
    final text = sentence.trim();
    if (text.isEmpty) return null;
    if (text.length > templates.limit('maxProofreadChars', 200)) return null;
    return text;
  }

  /// Purpose: Assemble one prompt.
  /// Inputs: The `task` name, `locale`, `analysis`, `catalog` and an optional
  /// `note`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The whole prompt is
  /// capped well under the Prompt API's 4000-token input limit; the parts are
  /// each capped first, so the cap is never reached by a runaway grammar
  /// excerpt silently dropping the rules at the end. The template is chosen by
  /// the same fallback order the content uses, so Traditional Chinese asks in
  /// Traditional Chinese and an unsupported language still asks in English.
  String? _build({
    required String task,
    required Locale locale,
    required SentenceAnalysis analysis,
    required ContentCatalog? catalog,
    required String? note,
  }) {
    final byLanguage = templates.tasks[task];
    if (byLanguage == null || byLanguage.isEmpty) return null;
    final keys = LocalizedStrings.lookupOrder(locale);
    final template = keys.map((key) => byLanguage[key]).nonNulls.firstOrNull;
    if (template == null) return null;
    final labels =
        keys.map((key) => templates.labels[key]).nonNulls.firstOrNull ??
        const <String, String>{};

    String label(String name, String fallback) => labels[name] ?? fallback;

    final sentence = _cap(
      analysis.normalized,
      templates.limit('maxSentenceChars', 200),
    );
    final buffer = StringBuffer()
      ..writeln(template.instruction)
      ..writeln()
      ..writeln('${label('sentence', 'Sentence')}: $sentence')
      ..writeln('${label('words', 'Words')}: ${_words(analysis)}');
    if (note != null) {
      buffer.writeln('${label('note', 'Flagged')}: $note');
    }
    final grammar = _grammar(analysis, catalog, locale);
    if (grammar.isNotEmpty) {
      buffer.writeln('${label('grammar', 'Grammar notes')}:');
      for (final line in grammar) {
        buffer.writeln('- $line');
      }
    }
    if (template.rules.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('${label('rules', 'Rules')}:');
      for (final rule in template.rules) {
        buffer.writeln('- $rule');
      }
    }
    return _cap(
      buffer.toString().trim(),
      templates.limit('maxPromptChars', 4000),
    );
  }

  /// Purpose: Render the token split as one line.
  /// Inputs: The `analysis`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Punctuation is left
  /// out and the recovered forms are included, because the forms are the part
  /// of the analysis a learner most often cannot see for themselves.
  String _words(SentenceAnalysis analysis) {
    final parts = <String>[];
    for (final token in analysis.tokens) {
      if (token.category == TokenCategory.punctuation) continue;
      final forms = token.forms.isEmpty
          ? ''
          : '+${token.forms.map((f) => f.name).join('+')}';
      parts.add('${token.surface} (${token.category.name}$forms)');
    }
    return parts.join(' / ');
  }

  /// Purpose: Quote the catalog's own explanation of each matched point.
  /// Inputs: The `analysis`, the `catalog` and the `locale`.
  /// Returns: `List<String>` — at most the configured number of points.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. This is the grounding:
  /// the model is handed the app's own teaching text and told not to
  /// contradict it, so an explanation cannot drift away from what the Grammar
  /// page says about the same point.
  List<String> _grammar(
    SentenceAnalysis analysis,
    ContentCatalog? catalog,
    Locale locale,
  ) {
    if (catalog == null) return const [];
    final lines = <String>[];
    final maxPoints = templates.limit('maxGrammarPoints', 3);
    final maxChars = templates.limit('maxGrammarExcerptChars', 300);
    for (final match in analysis.grammar) {
      if (lines.length >= maxPoints) break;
      final point = catalog.grammarById(match.pointId);
      if (point == null) continue;
      final meaning = point.meaning.resolveJoined(locale);
      final explanation = point.explanation.resolveJoined(locale);
      final body = explanation.isNotEmpty ? explanation : meaning;
      if (body.isEmpty) continue;
      lines.add('${point.pattern}: ${_cap(body, maxChars)}');
    }
    return lines;
  }

  /// Purpose: Quote a span of the sentence.
  /// Inputs: The `analysis` and the token range.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _span(SentenceAnalysis analysis, int first, int last) =>
      analysis.tokens.sublist(first, last + 1).map((t) => t.surface).join();

  /// Purpose: Cut a string to a maximum length.
  /// Inputs: `text`, `max`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. A hard cut with an
  /// ellipsis, not a word-boundary cut: this text goes to a model, not to a
  /// reader, and a predictable length matters more than a tidy edge.
  static String _cap(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}

/// Purpose: Read and parse the prompt template asset.
/// Inputs: Optional `bundle` for tests; defaults to `rootBundle`.
/// Returns: `Future<PromptTemplates>` — empty when the asset is unreadable.
/// Side effects: Reads one asset.
/// Notes: A failure is an empty set rather than an exception, which makes the
/// AI features unavailable while every deterministic part of the app keeps
/// working — the same rule the function-word table follows.
Future<PromptTemplates> loadPromptTemplates([AssetBundle? bundle]) async {
  try {
    final raw = await (bundle ?? rootBundle).loadString(
      'assets/content/prompts/sentence_explain.json',
    );
    return PromptTemplates.fromJson(jsonDecode(raw));
  } catch (_) {
    return PromptTemplates.empty;
  }
}
