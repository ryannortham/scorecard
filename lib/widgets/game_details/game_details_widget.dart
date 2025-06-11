import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/widgets/scoring/score_table.dart';
import 'package:goalkeeper/widgets/game_details/game_info_card.dart';
import 'package:goalkeeper/widgets/game_details/team_score_display.dart';
import 'package:goalkeeper/widgets/game_details/game_result_badge.dart';
import 'package:goalkeeper/services/game_state_service.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Data source types for the game details widget
enum GameDataSource {
  /// Use a static GameRecord (for game history)
  /// This mode uses pre-saved game data from device storage
  staticData,

  /// Use live data from providers (for current game)
  /// This mode uses real-time data from ScorePanelProvider and GameSetupProvider
  liveData,
}

/// A reusable widget for displaying game details that can work with both
/// static game data (from history) and live data (from current game providers)
///
/// **TWO MODES OF OPERATION:**
///
/// 1. **Game History Mode** (`GameDataSource.staticData`):
///    - Uses stored game data from device storage
///    - Data is immutable and doesn't change
///    - Creates isolated ScorePanelProvider instances for score tables
///    - Used for viewing completed games from history
///
/// 2. **Live Game Mode** (`GameDataSource.liveData`):
///    - Uses real-time data from existing providers in widget tree
///    - Data updates automatically when scores change
///    - Shares ScorePanelProvider with scoring tab for real-time sync
///    - Used for viewing current game details while scoring
class GameDetailsWidget extends StatelessWidget {
  /// Static game data (used when dataSource is staticData)
  final GameRecord? staticGame;

  /// The data source to use
  final GameDataSource dataSource;

  /// Live game events (used when dataSource is liveData)
  final List<GameEvent>? liveEvents;

  /// Optional scroll controller for screenshot capture
  final ScrollController? scrollController;

  const GameDetailsWidget({
    super.key,
    required this.dataSource,
    this.staticGame,
    this.liveEvents,
    this.scrollController,
  }) : assert(
            (dataSource == GameDataSource.staticData && staticGame != null) ||
                (dataSource == GameDataSource.liveData && liveEvents != null),
            'Must provide staticGame when using staticData or liveEvents when using liveData');

  /// Factory constructor for static data (game history)
  const GameDetailsWidget.fromStaticData({
    super.key,
    required GameRecord game,
    this.scrollController,
  })  : dataSource = GameDataSource.staticData,
        staticGame = game,
        liveEvents = null;

  /// Factory constructor for live data (current game)
  const GameDetailsWidget.fromLiveData({
    super.key,
    required List<GameEvent> events,
    this.scrollController,
  })  : dataSource = GameDataSource.liveData,
        staticGame = null,
        liveEvents = events;

  /// Determines if the game is complete based on timer events
  bool _isGameComplete(GameRecord game) {
    // If no events, it's definitely not complete
    if (game.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_pause event in quarter 4
    bool hasQ4ClockPause =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_pause');
    if (hasQ4ClockPause) return true;

    // Not enough evidence to consider the game complete
    return false;
  }

  /// Gets the current quarter based on the latest events
  int _getCurrentQuarter(GameRecord game) {
    if (game.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
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
  }) {
    if (dataSource == GameDataSource.liveData) {
      // For live data, use the existing ScorePanelAdapter from the widget tree
      // This ensures the score table shows real-time updates from the shared adapter
      // Use the live events instead of static game events
      return Consumer<ScorePanelAdapter>(
        builder: (context, scorePanelAdapter, child) {
          return ScoreTable(
            events: liveEvents ?? [], // Use live events for real-time updates
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            displayTeam: displayTeam,
            isHomeTeam: isHomeTeam,
            enabled: false, // Disable interactions in details view
            showHeader: false, // Hide team header
            showCounters: false, // Hide score counters
          );
        },
      );
    } else {
      // For static data, pass the current quarter directly to avoid provider listening
      final int currentQuarter = _getCurrentQuarter(game);
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
      );
    }
  }

  /// Builds the title for live games showing quarter and elapsed time
  String _buildLiveGameTitle(
      BuildContext context, ScorePanelAdapter scorePanelAdapter) {
    final gameStateService = GameStateService.instance;

    final currentQuarter = scorePanelAdapter.selectedQuarter;
    final elapsedTimeMs = gameStateService.getElapsedTimeInQuarter();

    // Format elapsed time using the same method as timer widget
    final timeStr = StopWatchTimer.getDisplayTime(elapsedTimeMs,
        hours: false, milliSecond: true);
    // Remove the last character (centiseconds)
    final formattedTime = timeStr.substring(0, timeStr.length - 1);

    return 'Q$currentQuarter $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    if (dataSource == GameDataSource.liveData) {
      // For live data, wrap in Consumer to rebuild when adapter data changes
      return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupAdapter, scorePanelAdapter, child) {
          final GameRecord game = _buildGameFromProviders(context);
          return _buildGameDetailsContent(context, game);
        },
      );
    } else {
      // For static data, just use the provided game data
      final GameRecord game = staticGame!;
      return _buildGameDetailsContent(context, game);
    }
  }

  Widget _buildGameDetailsContent(BuildContext context, GameRecord game) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;
    final bool isComplete = _isGameComplete(game);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Info Card
          GameInfoCard(
            icon: Icons.sports_rugby,
            title: '${game.homeTeam} vs ${game.awayTeam}',
            content: Text(
              DateFormat('EEEE, MMM d, yyyy').format(game.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          const SizedBox(height: 16),

          // Final Score Card
          dataSource == GameDataSource.liveData
              ? Consumer<ScorePanelAdapter>(
                  builder: (context, scorePanelAdapter, child) {
                    return GameInfoCard(
                      icon: Icons.outlined_flag,
                      title: _buildLiveGameTitle(context, scorePanelAdapter),
                      content: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TeamScoreDisplay(
                                  teamName: game.homeTeam,
                                  goals: game.homeGoals,
                                  behinds: game.homeBehinds,
                                  points: game.homePoints,
                                  isWinner: homeWins,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: TeamScoreDisplay(
                                  teamName: game.awayTeam,
                                  goals: game.awayGoals,
                                  behinds: game.awayBehinds,
                                  points: game.awayPoints,
                                  isWinner: awayWins,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GameResultBadge(
                            homeTeam: game.homeTeam,
                            awayTeam: game.awayTeam,
                            homePoints: game.homePoints,
                            awayPoints: game.awayPoints,
                            isGameComplete: isComplete,
                            isHistoryMode:
                                dataSource == GameDataSource.staticData,
                          ),
                        ],
                      ),
                    );
                  },
                )
              : GameInfoCard(
                  icon: Icons.outlined_flag,
                  title: 'Final Score',
                  content: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TeamScoreDisplay(
                              teamName: game.homeTeam,
                              goals: game.homeGoals,
                              behinds: game.homeBehinds,
                              points: game.homePoints,
                              isWinner: homeWins,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: TeamScoreDisplay(
                              teamName: game.awayTeam,
                              goals: game.awayGoals,
                              behinds: game.awayBehinds,
                              points: game.awayPoints,
                              isWinner: awayWins,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GameResultBadge(
                        homeTeam: game.homeTeam,
                        awayTeam: game.awayTeam,
                        homePoints: game.homePoints,
                        awayPoints: game.awayPoints,
                        isGameComplete: isComplete,
                        isHistoryMode: dataSource == GameDataSource.staticData,
                      ),
                    ],
                  ),
                ),

          // Quarter Breakdown Card
          const SizedBox(height: 16),
          GameInfoCard(
            icon: Icons.timeline,
            title: 'Quarter Breakdown',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home Team Label
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    game.homeTeam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: homeWins
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ),

                // Home Team Score Table
                _buildScoreTable(
                  context: context,
                  game: game,
                  displayTeam: game.homeTeam,
                  isHomeTeam: true,
                ),

                const SizedBox(height: 16),

                // Away Team Label
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    game.awayTeam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: awayWins
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ),

                // Away Team Score Table
                _buildScoreTable(
                  context: context,
                  game: game,
                  displayTeam: game.awayTeam,
                  isHomeTeam: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized widget for capturing game details as images
/// This renders the full content without scroll constraints
class CaptureableGameDetailsWidget extends StatelessWidget {
  final GameRecord game;

  const CaptureableGameDetailsWidget({super.key, required this.game});

  /// Determines if the game is complete based on timer events
  static bool _isGameCompleteForCapture(GameRecord game) {
    // If no events, it's definitely not complete
    if (game.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_pause event in quarter 4
    bool hasQ4ClockPause =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_pause');
    if (hasQ4ClockPause) return true;

    // Not enough evidence to consider the game complete
    return false;
  }

  /// Gets the current quarter based on the latest events
  static int _getCurrentQuarterForCapture(GameRecord game) {
    if (game.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
  }

  /// Builds the title for live games showing quarter and current status
  String _buildGameTitle(BuildContext context) {
    final isComplete = _isGameCompleteForCapture(game);
    if (isComplete) {
      return 'Final Score';
    } else {
      final currentQuarter = _getCurrentQuarterForCapture(game);

      // Get elapsed time from GameStateService
      final gameStateService = GameStateService.instance;
      final elapsedTimeMs = gameStateService.getElapsedTimeInQuarter();

      // Format elapsed time using the same method as timer widget
      final timeStr = StopWatchTimer.getDisplayTime(elapsedTimeMs,
          hours: false, milliSecond: true);
      // Remove the last character (centiseconds)
      final formattedTime = timeStr.substring(0, timeStr.length - 1);

      return 'Q$currentQuarter $formattedTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool homeWins = game.homePoints > game.awayPoints;
    final bool awayWins = game.awayPoints > game.homePoints;
    final bool isComplete = _isGameCompleteForCapture(game);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Match Info Card
          GameInfoCard(
            icon: Icons.sports_rugby,
            title: '${game.homeTeam} vs ${game.awayTeam}',
            content: Text(
              DateFormat('EEEE, MMM d, yyyy').format(game.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          const SizedBox(height: 16),

          // Score Card
          GameInfoCard(
            icon: Icons.outlined_flag,
            title: _buildGameTitle(context),
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TeamScoreDisplay(
                        teamName: game.homeTeam,
                        goals: game.homeGoals,
                        behinds: game.homeBehinds,
                        points: game.homePoints,
                        isWinner: homeWins,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: TeamScoreDisplay(
                        teamName: game.awayTeam,
                        goals: game.awayGoals,
                        behinds: game.awayBehinds,
                        points: game.awayPoints,
                        isWinner: awayWins,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GameResultBadge(
                  homeTeam: game.homeTeam,
                  awayTeam: game.awayTeam,
                  homePoints: game.homePoints,
                  awayPoints: game.awayPoints,
                  isGameComplete: isComplete,
                  isHistoryMode:
                      isComplete, // Use history mode only for completed games
                ),
              ],
            ),
          ),

          // Quarter Breakdown Card
          const SizedBox(height: 16),
          GameInfoCard(
            icon: Icons.timeline,
            title: 'Quarter Breakdown',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home Team Label
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    game.homeTeam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: homeWins
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ),

                // Home Team Score Table
                _buildCaptureScoreTable(
                  context: context,
                  game: game,
                  displayTeam: game.homeTeam,
                  isHomeTeam: true,
                ),

                const SizedBox(height: 16),

                // Away Team Label
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Text(
                    game.awayTeam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: awayWins
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ),

                // Away Team Score Table
                _buildCaptureScoreTable(
                  context: context,
                  game: game,
                  displayTeam: game.awayTeam,
                  isHomeTeam: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a score table specifically for capture (no interactivity, full content)
  Widget _buildCaptureScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
  }) {
    final int currentQuarter = _getCurrentQuarterForCapture(game);

    return ScoreTable(
      events: game.events,
      homeTeam: game.homeTeam,
      awayTeam: game.awayTeam,
      displayTeam: displayTeam,
      isHomeTeam: isHomeTeam,
      enabled: false, // Disable interactions in capture
      showHeader: false, // Hide team header
      showCounters: false, // Hide score counters
      currentQuarter: currentQuarter, // Pass quarter directly
    );
  }
}
