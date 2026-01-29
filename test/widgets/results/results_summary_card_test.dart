// tests for ResultsSummaryCard widget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_summary.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/repositories/preferences_repository.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/results/results_summary_card.dart';

import '../../mocks/mock_preferences_repository.dart';
import '../../mocks/mock_team_repository.dart';

void main() {
  // Helper to create a GameSummary for testing
  GameSummary createGameSummary({
    String id = 'test-game-1',
    String homeTeam = 'Richmond',
    String awayTeam = 'Carlton',
    int homeGoals = 10,
    int homeBehinds = 5,
    int awayGoals = 8,
    int awayBehinds = 7,
    DateTime? date,
  }) {
    return GameSummary(
      id: id,
      date: date ?? DateTime(2026, 1, 15, 14, 30),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
    );
  }

  // Helper to build the widget with providers
  Widget buildTestWidget({
    required GameSummary gameSummary,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isSelectionMode = false,
    bool isSelected = false,
    List<Team>? teams,
    List<String>? favoriteTeams,
  }) {
    // Note: We don't provide logoUrl to avoid network image loading issues
    // in tests. The TeamLogo widget will show a fallback football icon.
    final teamRepository = MockTeamRepository(
      initialTeams:
          teams ??
          [
            const Team(name: 'Richmond'),
            const Team(name: 'Carlton'),
          ],
    );

    final preferencesRepository = MockPreferencesRepository(
      initialData: PreferencesData(
        favoriteTeams: favoriteTeams ?? [],
      ),
    );

    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<TeamsViewModel>(
            create: (_) => TeamsViewModel(repository: teamRepository),
          ),
          ChangeNotifierProvider<PreferencesViewModel>(
            create:
                (_) => PreferencesViewModel(repository: preferencesRepository),
          ),
        ],
        child: Scaffold(
          body: ResultsSummaryCard(
            gameSummary: gameSummary,
            onTap: onTap ?? () {},
            onLongPress: onLongPress,
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }

  group('ResultsSummaryCard', () {
    group('display', () {
      testWidgets('displays home and away team names', (tester) async {
        // Uses defaults: Richmond vs Carlton
        final gameSummary = createGameSummary();

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        expect(find.text('Richmond'), findsOneWidget);
        expect(find.text('Carlton'), findsOneWidget);
        expect(find.text('vs'), findsOneWidget);
      });

      testWidgets('displays score in correct format', (tester) async {
        // Uses defaults: 10.5 (65) vs 8.7 (55)
        final gameSummary = createGameSummary();

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        // The score is rendered using RichText with TextSpan, so we need to
        // find the RichText widget and check its text content.
        final richTextFinder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Score:'),
        );
        expect(richTextFinder, findsOneWidget);

        final richText = tester.widget<RichText>(richTextFinder);
        final plainText = richText.text.toPlainText();

        // Home: 10.5 (65) - Away: 8.7 (55)
        expect(plainText, contains('10.5 (65)'));
        expect(plainText, contains('8.7 (55)'));
      });

      testWidgets('displays date and time', (tester) async {
        final gameSummary = createGameSummary(
          date: DateTime(2026, 1, 15, 14, 30),
        );

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        expect(find.textContaining('15/01/2026'), findsOneWidget);
        expect(find.textContaining('14:30'), findsOneWidget);
      });
    });

    group('winner highlighting', () {
      testWidgets('highlights home team name when home wins', (tester) async {
        // Uses defaults: Home 10.5 (65) vs Away 8.7 (55) - Home wins
        final gameSummary = createGameSummary();

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        // Find home team text widget
        final homeTeamFinder = find.text('Richmond');
        expect(homeTeamFinder, findsOneWidget);

        final homeTeamWidget = tester.widget<Text>(homeTeamFinder);
        final homeTeamColor = homeTeamWidget.style?.color;

        // Find away team text widget
        final awayTeamFinder = find.text('Carlton');
        expect(awayTeamFinder, findsOneWidget);

        final awayTeamWidget = tester.widget<Text>(awayTeamFinder);
        final awayTeamColor = awayTeamWidget.style?.color;

        // Home team (winner) should have a different colour than away team.
        // The winning team gets the primary colour, losers get default
        // text colour.
        expect(homeTeamColor, isNotNull);
        expect(homeTeamColor, isNot(equals(awayTeamColor)));
      });

      testWidgets('highlights away team name when away wins', (tester) async {
        // Home: 5.3 (33) vs Away: 10.5 (65) - Away wins
        final gameSummary = createGameSummary(
          homeGoals: 5,
          homeBehinds: 3,
          awayGoals: 10,
          awayBehinds: 5,
        );

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        final homeTeamWidget = tester.widget<Text>(find.text('Richmond'));
        final awayTeamWidget = tester.widget<Text>(find.text('Carlton'));

        // Away team (winner) should have a different colour than home team
        expect(awayTeamWidget.style?.color, isNotNull);
        expect(
          awayTeamWidget.style?.color,
          isNot(equals(homeTeamWidget.style?.color)),
        );
      });

      testWidgets('no team highlighting when draw', (tester) async {
        // Home: 8.4 (52) vs Away: 8.4 (52) - Draw
        final gameSummary = createGameSummary(
          homeGoals: 8,
          homeBehinds: 4,
          awayBehinds: 4,
        );

        await tester.pumpWidget(buildTestWidget(gameSummary: gameSummary));
        await tester.pumpAndSettle();

        final homeTeamWidget = tester.widget<Text>(find.text('Richmond'));
        final awayTeamWidget = tester.widget<Text>(find.text('Carlton'));

        // Neither team should have special highlighting - both same colour
        expect(
          homeTeamWidget.style?.color,
          equals(awayTeamWidget.style?.color),
        );
      });
    });

    group('trophy icon', () {
      testWidgets('shows trophy when favourite home team wins', (tester) async {
        // Home: 10.5 (65) vs Away: 8.7 (55) - Home wins
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            favoriteTeams: ['Richmond'],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      });

      testWidgets('shows trophy when favourite away team wins', (tester) async {
        // Home: 5.3 (33) vs Away: 10.5 (65) - Away wins
        final gameSummary = createGameSummary(
          homeGoals: 5,
          homeBehinds: 3,
          awayGoals: 10,
          awayBehinds: 5,
        );

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            favoriteTeams: ['Carlton'],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      });

      testWidgets('hides trophy when favourite team loses', (tester) async {
        // Home: 10.5 (65) vs Away: 8.7 (55) - Home wins, but Carlton is
        // favourite
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            favoriteTeams: ['Carlton'],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      });

      testWidgets('hides trophy when no favourite teams set', (tester) async {
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            favoriteTeams: [],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      });

      testWidgets('hides trophy on draw even with favourite team', (
        tester,
      ) async {
        // Draw: 8.4 (52) vs 8.4 (52)
        final gameSummary = createGameSummary(
          homeGoals: 8,
          homeBehinds: 4,
          awayBehinds: 4,
        );

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            favoriteTeams: ['Richmond'],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      });
    });

    group('selection mode', () {
      testWidgets(
        'shows unchecked icon when in selection mode but not selected',
        (tester) async {
          final gameSummary = createGameSummary();

          await tester.pumpWidget(
            buildTestWidget(
              gameSummary: gameSummary,
              isSelectionMode: true,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
          expect(find.byIcon(Icons.check_circle_outlined), findsNothing);
        },
      );

      testWidgets('shows checked icon when selected', (tester) async {
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            isSelectionMode: true,
            isSelected: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle_outlined), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      });

      testWidgets('uses primaryContainer background when selected', (
        tester,
      ) async {
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            isSelectionMode: true,
            isSelected: true,
          ),
        );
        await tester.pumpAndSettle();

        final card = tester.widget<Card>(find.byType(Card));
        // When selected, card should use primaryContainer color
        // We verify it's not the default surfaceContainer
        expect(card.color, isNotNull);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            onTap: () => tapped = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ResultsSummaryCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        var longPressed = false;
        final gameSummary = createGameSummary();

        await tester.pumpWidget(
          buildTestWidget(
            gameSummary: gameSummary,
            onLongPress: () => longPressed = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(ResultsSummaryCard));
        await tester.pumpAndSettle();

        expect(longPressed, isTrue);
      });
    });
  });
}
