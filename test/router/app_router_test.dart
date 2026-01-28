import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/router/app_router.dart';
import 'package:scorecard/models/score.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/widgets/navigation/bottom_nav_bar.dart';
import 'package:scorecard/screens/scoring/scoring_setup_screen.dart';
import 'package:scorecard/screens/scoring/scoring_screen.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';

// Mock ViewModels
class MockGameViewModel extends ChangeNotifier implements GameViewModel {
  @override
  bool get hasActiveGame => false;
  @override
  int get quarterMinutes => 15;
  @override
  int get quarterMSec => 15 * 60 * 1000;
  @override
  String get homeTeam => 'Home';
  @override
  String get awayTeam => 'Away';
  @override
  int get currentQuarter => 1;
  @override
  String get currentGameId => 'test-id';
  @override
  List<GameEvent> get gameEvents => [];
  @override
  int get homeGoals => 0;
  @override
  int get homeBehinds => 0;
  @override
  int get awayGoals => 0;
  @override
  int get awayBehinds => 0;
  @override
  int get homePoints => 0;
  @override
  int get awayPoints => 0;
  @override
  int get selectedQuarter => 1;
  @override
  bool get isTimerRunning => false;
  @override
  bool get isCountdownTimer => true;
  @override
  int get timerRawTime => 0;
  @override
  Stream<int> get timerStream => Stream.value(0);
  @override
  DateTime get gameDate => DateTime.now();
  
  @override
  int getRemainingTimeInQuarter() => 0;
  @override
  int getElapsedTimeInQuarter() => 0;
  
  @override
  int getScore({required bool isHomeTeam, required bool isGoal}) => 0;
  @override
  bool hasEventInCurrentQuarter({required bool isHomeTeam, required bool isGoal}) => false;
  
  @override
  void configureGame({required String homeTeam, required String awayTeam, required DateTime gameDate, required int quarterMinutes, required bool isCountdownTimer}) {}
  @override
  void resetGame() {}
  @override
  void configureTimer({required bool isCountdownMode, required int quarterMaxTime}) {}
  @override
  void addGameEventListener(VoidCallback listener) {}
  @override
  void removeGameEventListener(VoidCallback listener) {}
  @override
  void addTimerStateListener(VoidCallback listener) {}
  @override
  void removeTimerStateListener(VoidCallback listener) {}
  @override
  void addScoreChangeListener(VoidCallback listener) {}
  @override
  void removeScoreChangeListener(VoidCallback listener) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPreferencesViewModel extends ChangeNotifier implements PreferencesViewModel {
  @override
  bool get loaded => true;
  @override
  String get colorTheme => 'blue';
  @override
  ThemeMode get themeMode => ThemeMode.system;
  @override
  Color getThemeColor() => Colors.blue;
  @override
  bool get useTallys => true;
  @override
  String? getDefaultFavoriteTeam() => null;
  @override
  int get quarterMinutes => 15;
  @override
  bool get isCountdownTimer => true;
  @override
  bool get supportsDynamicColors => false;
  @override
  List<String> get favoriteTeams => [];
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTeamsViewModel extends ChangeNotifier implements TeamsViewModel {
   @override
  List<Team> get teams => [];
  
  @override
  Team? findTeamByName(String name) => null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('App Router Tests', () {
    late MockGameViewModel mockGameViewModel;
    late MockPreferencesViewModel mockPreferencesViewModel;
    late MockTeamsViewModel mockTeamsViewModel;

    setUp(() {
      mockGameViewModel = MockGameViewModel();
      mockPreferencesViewModel = MockPreferencesViewModel();
      mockTeamsViewModel = MockTeamsViewModel();
    });

    testWidgets('Initial route should be /scoring and show ScoringSetupScreen with BottomNavBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameViewModel>.value(value: mockGameViewModel),
            ChangeNotifierProvider<PreferencesViewModel>.value(value: mockPreferencesViewModel),
            ChangeNotifierProvider<TeamsViewModel>.value(value: mockTeamsViewModel),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ScoringSetupScreen), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('Navigating to /scoring-game should hide BottomNavBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameViewModel>.value(value: mockGameViewModel),
            ChangeNotifierProvider<PreferencesViewModel>.value(value: mockPreferencesViewModel),
            ChangeNotifierProvider<TeamsViewModel>.value(value: mockTeamsViewModel),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Navigate to scoring-game
      appRouter.go('/scoring-game');
      await tester.pumpAndSettle();

      expect(find.byType(ScoringScreen), findsOneWidget);
      expect(find.byType(BottomNavBar), findsNothing);
    });
  });
}
