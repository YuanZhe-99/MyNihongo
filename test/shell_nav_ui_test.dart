import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_nihongo/app/theme.dart';
import 'package:my_nihongo/l10n/app_localizations.dart';
import 'package:my_nihongo/shared/providers/app_settings.dart';
import 'package:my_nihongo/shared/utils/adaptive_layout.dart';
import 'package:my_nihongo/shared/widgets/shell_scaffold.dart';

/// Purpose: Test that the shell swaps its bottom bar for a rail on wide windows.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The rail is chosen on width alone, deliberately unlike the app-wide
/// split rule, so the case worth pinning hardest is a phone in landscape: wide
/// enough for a rail, far too short to split. The five destinations are stubbed
/// with empty pages so this exercises the shell and nothing behind it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The Expressive bottom bar (the default style) has this key.
  const island = ValueKey('floatingNavBarIsland');

  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    double height, {
    AppUiStyle uiStyle = AppUiStyle.expressive,
    NavPlacement placement = NavPlacement.sideOnWide,
    bool railRight = false,
    String initialLocation = '/learn',
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (context, state, child) => ShellScaffold(child: child),
          routes: [
            for (final path in ShellScaffold.routes)
              GoRoute(
                path: path,
                builder: (context, state) => path == '/vocab'
                    // A long list laid out the way the real tab pages are:
                    // explicit padding passed through navBarAwarePadding.
                    ? Scaffold(
                        body: Builder(
                          builder: (context) => ListView(
                            padding: navBarAwarePadding(
                              context,
                              const EdgeInsets.only(bottom: 16),
                            ),
                            children: [
                              for (var i = 0; i < 40; i++)
                                SizedBox(height: 56, child: Text('row $i')),
                            ],
                          ),
                        ),
                      )
                    : Scaffold(body: Center(child: Text('page $path'))),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWithValue(
            AppSettingsNotifier.fixed(
              AppSettings(
                uiStyle: uiStyle,
                navPlacement: placement,
                navRailOnRight: railRight,
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('bottom bar style', () {
    testWidgets('the default Expressive style floats the bar as an island', (
      tester,
    ) async {
      await pumpAt(tester, 412, 915);
      expect(find.byKey(island), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // Only the selected destination shows its label; the others are icons
      // with tooltips.
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Vocabulary'), findsNothing);
      expect(find.byTooltip('Vocabulary'), findsOneWidget);
    });

    testWidgets('the Material 3 style keeps the classic bar', (tester) async {
      await pumpAt(tester, 412, 915, uiStyle: AppUiStyle.material3);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(island), findsNothing);
    });

    testWidgets('the rail ignores the setting', (tester) async {
      await pumpAt(tester, 933, 704);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byKey(island), findsNothing);
    });

    testWidgets('tapping an island destination navigates', (tester) async {
      await pumpAt(tester, 412, 915);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('page /settings'), findsOneWidget);
    });
  });

  group('content behind the Expressive bar (0.6.1)', () {
    testWidgets('the last row clears the floating bar', (tester) async {
      await pumpAt(tester, 412, 915, initialLocation: '/vocab');
      final barTop = tester.getRect(find.byKey(island)).top;
      // Before scrolling, rows are drawn behind the bar.
      expect(tester.getRect(find.text('row 16')).bottom, greaterThan(barTop));
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('row 39')).bottom,
        lessThanOrEqualTo(barTop),
      );
    });

    testWidgets('Material 3 keeps content above its bar', (tester) async {
      await pumpAt(
        tester,
        412,
        915,
        uiStyle: AppUiStyle.material3,
        initialLocation: '/vocab',
      );
      final barTop = tester.getRect(find.byType(NavigationBar)).top;
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        lessThanOrEqualTo(barTop),
      );
    });
  });

  group('navigation position (0.6.1)', () {
    test('the default is bottom everywhere', () {
      expect(const AppSettings().navPlacement, NavPlacement.bottom);
    });

    for (final style in AppUiStyle.values) {
      testWidgets('bottom keeps the bar on a wide window (${style.name})', (
        tester,
      ) async {
        await pumpAt(
          tester,
          933,
          704,
          uiStyle: style,
          placement: NavPlacement.bottom,
        );
        expect(find.byType(NavigationRail), findsNothing);
        expect(
          style == AppUiStyle.expressive
              ? find.byKey(island)
              : find.byType(NavigationBar),
          findsOneWidget,
        );
      });

      testWidgets('side puts the rail on a phone too (${style.name})', (
        tester,
      ) async {
        await pumpAt(
          tester,
          412,
          915,
          uiStyle: style,
          placement: NavPlacement.side,
        );
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byKey(island), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the rail can sit on the right (${style.name})', (
        tester,
      ) async {
        await pumpAt(tester, 933, 704, uiStyle: style, railRight: true);
        final rail = tester.getRect(find.byType(NavigationRail));
        expect(rail.right, 933);
        expect(find.text('page /learn'), findsOneWidget);
      });
    }

    testWidgets('side on wide keeps the bar on a phone', (tester) async {
      await pumpAt(tester, 412, 915);
      expect(find.byKey(island), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('the rail sits on the left by default', (tester) async {
      await pumpAt(tester, 933, 704);
      expect(tester.getTopLeft(find.byType(NavigationRail)).dx, 0);
    });
  });

  testWidgets('a phone in portrait keeps the bottom navigation bar', (
    tester,
  ) async {
    await pumpAt(tester, 412, 915); // Pixel 9
    expect(find.byKey(island), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a Z Fold 8 unfolded moves navigation to the side', (
    tester,
  ) async {
    await pumpAt(tester, 933, 704);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('a phone in landscape gets a rail even though it cannot split', (
    tester,
  ) async {
    // The reason the rail has a rule of its own: at 412 logical pixels tall a
    // bottom bar would spend a fifth of the height, and width is what is spare.
    await pumpAt(tester, 915, 412);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rail carries the same five destinations, in order', (
    tester,
  ) async {
    await pumpAt(tester, 1600, 900); // desktop
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(ShellScaffold.routes.length));
    expect(rail.selectedIndex, 0);
  });

  testWidgets('tapping a rail destination navigates', (tester) async {
    await pumpAt(tester, 933, 704);
    expect(find.text('page /learn'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.translate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('page /kana'), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 1);
  });

  testWidgets('tapping a bottom-bar destination navigates', (tester) async {
    await pumpAt(tester, 412, 915, uiStyle: AppUiStyle.material3);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('page /settings'), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 4);
  });
}
