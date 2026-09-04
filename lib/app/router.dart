import 'package:go_router/go_router.dart';

import '../features/grammar/views/grammar_page.dart';
import '../features/kana/views/kana_page.dart';
import '../features/learn/views/learn_page.dart';
import '../features/lessons/views/scenario_page.dart';
import '../features/quiz/models/quiz_config.dart';
import '../features/quiz/views/quiz_page.dart';
import '../features/sentence/views/sentence_lab_page.dart';
import '../features/settings/views/settings_page.dart';
import '../features/vocab/views/vocab_page.dart';
import '../features/writing/views/writing_practice_page.dart';
import '../shared/widgets/shell_scaffold.dart';

/// Purpose: Build the app's router.
/// Inputs: `initialLocation` — the tab to open on, defaulting to Learn.
/// Returns: `GoRouter`.
/// Side effects: None.
/// Notes: The five shell tabs, in the order the bottom bar and the rail show
/// them; `ShellScaffold.routes` holds the same list, keep the two in step. The
/// sentence lab is a sixth route but not a sixth tab — see the comment on it.
/// `main()` passes the tab the app was last on, read before `runApp`, so the
/// app opens where the user left it without a visible jump from Learn.
GoRouter buildAppRouter({String initialLocation = '/learn'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/learn', builder: (context, state) => const LearnPage()),
        GoRoute(path: '/kana', builder: (context, state) => const KanaPage()),
        GoRoute(path: '/vocab', builder: (context, state) => const VocabPage()),
        GoRoute(
          path: '/grammar',
          builder: (context, state) => const GrammarPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    // Outside the shell on purpose: the five tabs are the reference the app is
    // built around, and the lab is something you do *to* a sentence you
    // already have. It is opened from Learn, from the reference pages and from
    // any example, and it takes the whole window so a long sentence has room.
    // A quiz is entered with a purpose and left when it is finished, like the
    // lab; it is not a place to browse, so it is not a tab.
    GoRoute(
      path: '/quiz',
      builder: (context, state) =>
          QuizPage(config: state.extra! as QuizConfig),
    ),
    // Writing is entered from a unit and left when it is finished, the
    // way a quiz is, so it is a full-window route rather than a tab.
    GoRoute(
      path: '/scenario',
      builder: (context, state) =>
          ScenarioPage(args: state.extra! as ScenarioArgs),
    ),
    GoRoute(
      path: '/writing',
      builder: (context, state) =>
          WritingPracticePage(prompt: state.extra! as WritingPrompt),
    ),
    GoRoute(
      path: '/lab',
      builder: (context, state) =>
          SentenceLabPage(initialSentence: state.extra as String?),
    ),
  ],
);
