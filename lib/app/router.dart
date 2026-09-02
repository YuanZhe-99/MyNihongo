import 'package:go_router/go_router.dart';

import '../features/grammar/views/grammar_page.dart';
import '../features/kana/views/kana_page.dart';
import '../features/learn/views/learn_page.dart';
import '../features/settings/views/settings_page.dart';
import '../features/vocab/views/vocab_page.dart';
import '../shared/widgets/shell_scaffold.dart';

/// The five shell tabs, in the order the bottom bar and the rail show them.
/// `ShellScaffold.routes` holds the same list; keep the two in step.
final appRouter = GoRouter(
  initialLocation: '/learn',
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
  ],
);
