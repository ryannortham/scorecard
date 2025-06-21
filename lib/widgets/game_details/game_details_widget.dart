import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/widgets/game_details/game_info_card.dart';
import 'package:scorecard/widgets/game_details/game_score_section.dart';
import 'package:scorecard/widgets/game_details/live_game_title_builder.dart';
import 'package:scorecard/widgets/game_details/quarter_breakdown_section.dart';
import 'package:scorecard/widgets/scoring/score_table.dart';

/// Data source types for the game details widget
enum GameDataSource {
  /// Use a static GameRecord (for game history)
  staticData,

  /// Use live data from providers (for current game)
  liveData,
}

/// A unified widget for displaying game details that works with both
/// static game data (from history) and live data (from current game)
class GameDetailsWidget extends StatelessWidget {
  /// Static game data (used when dataSource is staticData)
  final GameRecord? staticGame;

  /// The data source to use
  final GameDataSource dataSource;

  /// Live game events (used when dataSource is liveData)
  final List<GameEvent>? liveEvents;

  /// Optional scroll controller
  final ScrollController? scrollController;

  /// Whether to enable scrolling (disable for screenshots)
  final bool enableScrolling;

  const GameDetailsWidget({
    super.key,
    required this.dataSource,
    this.staticGame,
    this.liveEvents,
    this.scrollController,
    this.enableScrolling = true,
  }) : assert(
            (dataSource == GameDataSource.staticData && staticGame != null) ||
                (dataSource == GameDataSource.liveData && liveEvents != null),
            'Must provide staticGame when using staticData or liveEvents when using liveData');

  /// Factory constructor for static data (game history)
  const GameDetailsWidget.fromStaticData({
    super.key,
    required GameRecord game,
    this.scrollController,
    this.enableScrolling = true,
  })  : dataSource = GameDataSource.staticData,
        staticGame = game,
        liveEvents = null;

  /// Factory constructor for live data (current game)
  const GameDetailsWidget.fromLiveData({
    super.key,
    required List<GameEvent> events,
    this.scrollController,
    this.enableScrolling = true,
  })  : dataSource = GameDataSource.liveData,
        staticGame = null,
        liveEvents = events;

  /// Determines if the game is complete based on timer events
  static bool isGameComplete(GameRecord game) {
    if (game.events.isEmpty) return false;
    return game.events.any((e) => e.quarter == 4 && e.type == 'clock_end');
  }

  /// Determines if the trophy icon should be shown (game complete and favorite team won)
  bool _shouldShowTrophyIcon(
      GameRecord game, UserPreferencesProvider userPrefs) {
    // Game must be complete
    if (!isGameComplete(game)) return false;

    // Must have a favorite team set
    if (userPrefs.favoriteTeam.isEmpty) return false;

    // Check if favorite team won
    final homePoints = game.homePoints;
    final awayPoints = game.awayPoints;

    if (homePoints == awayPoints) return false; // No winner in a tie

    final favoriteIsHome = game.homeTeam == userPrefs.favoriteTeam;
    final favoriteIsAway = game.awayTeam == userPrefs.favoriteTeam;

    // Favorite team must be playing in this game
    if (!favoriteIsHome && !favoriteIsAway) return false;

    // Check if favorite team won
    if (favoriteIsHome && homePoints > awayPoints) return true;
    if (favoriteIsAway && awayPoints > homePoints) return true;

    return false;
  }

  /// Gets the current quarter based on the latest events
  static int getCurrentQuarter(GameRecord game) {
    if (game.events.isEmpty) return 1;
    return game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
  }

  /// Builds a GameRecord from current provider data (for live data)
  GameRecord _buildGameFromProviders(BuildContext context) {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(context);
    final scorePanelAdapter = Provider.of<ScorePanelAdapter>(context);

    return GameRecord(
      id: 'current-game', // Temporary ID for current game
      date: gameSetupAdapter.gameDate,
      homeTeam: gameSetupAdapter.homeTeam,
      awayTeam: gameSetupAdapter.awayTeam,
      quarterMinutes: gameSetupAdapter.quarterMinutes,
      isCountdownTimer: gameSetupAdapter.isCountdownTimer,
      events: liveEvents ?? [],
      homeGoals: scorePanelAdapter.homeGoals,
      homeBehinds: scorePanelAdapter.homeBehinds,
      awayGoals: scorePanelAdapter.awayGoals,
      awayBehinds: scorePanelAdapter.awayBehinds,
    );
  }

  /// Builds a score table widget that correctly handles live vs static data
  Widget _buildScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
    ScorePanelAdapter? scorePanelAdapter,
  }) {
    if (dataSource == GameDataSource.liveData && scorePanelAdapter != null) {
      // Use provided ScorePanelAdapter for real-time updates (no Consumer needed)
      return ScoreTable(
        events: liveEvents ?? [],
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        displayTeam: displayTeam,
        isHomeTeam: isHomeTeam,
        enabled: false,
        showHeader: false,
        showCounters: false, // Hide score counters
        isCompletedGame: false, // Live game is not completed
      );
    } else {
      // For static data, pass the current quarter directly to avoid provider listening
      final int currentQuarter = getCurrentQuarter(game);
      final bool isCompleted = isGameComplete(game);
      return ScoreTable(
        events: game.events,
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        displayTeam: displayTeam,
        isHomeTeam: isHomeTeam,
        enabled: false, // Disable interactions in details view
        showHeader: false, // Hide team header
        showCounters: false, // Hide score counters
        currentQuarter:
            currentQuarter, // Pass quarter directly to avoid provider listening
        isCompletedGame:
            isCompleted, // Pass completion status to show all quarters
      );
    }
  }

  /// Builds the title for live games showing quarter and elapsed time
  String _buildLiveGameTitle(
      BuildContext context, ScorePanelAdapter scorePanelAdapter) {
    return LiveGameTitleBuilder.buildTitle(context, scorePanelAdapter);
  }

  @override
  Widget build(BuildContext context) {
    if (dataSource == GameDataSource.liveData) {
      // For live data, wrap in Consumer to rebuild when adapter data changes
      return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupAdapter, scorePanelAdapter, child) {
          final GameRecord game = _buildGameFromProviders(context);
          return _buildGameDetailsContent(context, game, scorePanelAdapter);
        },
      );
    } else {
      // For static data, just use the provided game data
      final GameRecord game = staticGame!;
      return _buildGameDetailsContent(context, game, null);
    }
  }

  Widget _buildGameDetailsContent(BuildContext context, GameRecord game,
      ScorePanelAdapter? scorePanelAdapter) {
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final bool shouldShowTrophy = _shouldShowTrophyIcon(game, userPrefs);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameInfoCard(
          icon: shouldShowTrophy
              ? Icons.emoji_events_outlined
              : Icons.event_outlined,
          title: '${game.homeTeam} vs ${game.awayTeam}',
          content: Text(
            DateFormat('EEEE, MMM d, yyyy').format(game.date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        dataSource == GameDataSource.liveData && scorePanelAdapter != null
            ? (() {
                final liveTitle =
                    _buildLiveGameTitle(context, scorePanelAdapter);
                return GameScoreSection(
                  game: game,
                  isLiveData: true,
                  liveTitleOverride: liveTitle,
                );
              })()
            : GameScoreSection(
                game: game,
                isLiveData: false,
              ),
        const SizedBox(height: 16),
        QuarterBreakdownSection(
          game: game,
          isLiveData: dataSource == GameDataSource.liveData,
          liveEvents: liveEvents,
          scoreTableBuilder: ({
            required BuildContext context,
            required GameRecord game,
            required String displayTeam,
            required bool isHomeTeam,
          }) =>
              _buildScoreTable(
            context: context,
            game: game,
            displayTeam: displayTeam,
            isHomeTeam: isHomeTeam,
            scorePanelAdapter: scorePanelAdapter,
          ),
        ),
      ],
    );

    if (enableScrolling) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16.0),
        child: content,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      );
    }
  }
}
