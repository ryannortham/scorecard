import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/game_analysis_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/score_table_builder_service.dart';
import 'package:scorecard/widgets/adaptive_title.dart';

/// A unified widget for displaying game details
class GameDetailsWidget extends StatelessWidget {
  final GameRecord? staticGame;
  final List<GameEvent>? liveEvents;
  final ScrollController? scrollController;
  final bool enableScrolling;
  final bool isLiveData;

  const GameDetailsWidget({
    super.key,
    this.staticGame,
    this.liveEvents,
    this.scrollController,
    this.enableScrolling = true,
  }) : isLiveData = staticGame == null;

  /// Factory constructor for static data (game history)
  const GameDetailsWidget.fromStaticData({
    super.key,
    required GameRecord game,
    this.scrollController,
    this.enableScrolling = true,
  }) : staticGame = game,
       liveEvents = null,
       isLiveData = false;

  /// Factory constructor for live data (current game)
  const GameDetailsWidget.fromLiveData({
    super.key,
    required List<GameEvent> events,
    this.scrollController,
    this.enableScrolling = true,
  }) : staticGame = null,
       liveEvents = events,
       isLiveData = true;

  @override
  Widget build(BuildContext context) {
    if (isLiveData) {
      return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetup, scorePanel, child) {
          final game = _buildLiveGame(gameSetup, scorePanel);
          return _buildContent(context, game, scorePanel);
        },
      );
    } else {
      return _buildContent(context, staticGame!, null);
    }
  }

  GameRecord _buildLiveGame(GameSetupAdapter gameSetup, ScorePanelAdapter scorePanel) {
    return GameRecord(
      id: 'current-game',
      date: gameSetup.gameDate,
      homeTeam: gameSetup.homeTeam,
      awayTeam: gameSetup.awayTeam,
      quarterMinutes: gameSetup.quarterMinutes,
      isCountdownTimer: gameSetup.isCountdownTimer,
      events: liveEvents ?? [],
      homeGoals: scorePanel.homeGoals,
      homeBehinds: scorePanel.homeBehinds,
      awayGoals: scorePanel.awayGoals,
      awayBehinds: scorePanel.awayBehinds,
    );
  }

  Widget _buildContent(BuildContext context, GameRecord game, ScorePanelAdapter? scorePanel) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GameInfoSection(game: game, isLiveData: isLiveData, scorePanel: scorePanel),
        const SizedBox(height: 16),
        _ScoreSection(game: game, isLiveData: isLiveData, scorePanel: scorePanel),
        const SizedBox(height: 16),
        _QuarterBreakdownSection(game: game, liveEvents: liveEvents, scorePanel: scorePanel),
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

/// Simple card wrapper for consistent styling
class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveTitle(
                    title: title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.left,
                    minScaleFactor: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Game info section (title, date, trophy)
class _GameInfoSection extends StatelessWidget {
  final GameRecord game;
  final bool isLiveData;
  final ScorePanelAdapter? scorePanel;

  const _GameInfoSection({
    required this.game,
    required this.isLiveData,
    this.scorePanel,
  });

  @override
  Widget build(BuildContext context) {
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final shouldShowTrophy = GameAnalysisService.shouldShowTrophyIcon(game, userPrefs);

    return _GameCard(
      icon: shouldShowTrophy ? Icons.emoji_events_outlined : Icons.event_outlined,
      title: '${game.homeTeam} vs ${game.awayTeam}',
      child: Text(
        DateFormat('EEEE, MMM d, yyyy').format(game.date),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// Score section
class _ScoreSection extends StatelessWidget {
  final GameRecord game;
  final bool isLiveData;
  final ScorePanelAdapter? scorePanel;

  const _ScoreSection({
    required this.game,
    required this.isLiveData,
    this.scorePanel,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = GameAnalysisService.isGameComplete(game);
    final title = _getScoreTitle(isComplete);

    return _GameCard(
      icon: Icons.outlined_flag,
      title: title,
      child: Column(
        children: [
          _TeamScoresRow(game: game),
          const SizedBox(height: 16),
          _GameResultBadge(game: game, isComplete: isComplete),
        ],
      ),
    );
  }

  String _getScoreTitle(bool isComplete) {
    if (isLiveData && scorePanel != null) {
      final gameState = GameStateService.instance;
      final quarter = scorePanel!.selectedQuarter;
      final timeMs = gameState.getElapsedTimeInQuarter();
      final timeStr = StopWatchTimer.getDisplayTime(timeMs, hours: false, milliSecond: true);
      final formattedTime = timeStr.substring(0, timeStr.length - 1);
      return 'In Progress: Q$quarter $formattedTime';
    }
    
    if (isComplete) return 'Final Score';
    
    // For static incomplete games, build title from events
    return GameAnalysisService.buildStaticGameTitle(game);
  }
}

/// Team scores display
class _TeamScoresRow extends StatelessWidget {
  final GameRecord game;

  const _TeamScoresRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final homeWins = game.homePoints > game.awayPoints;
    final awayWins = game.awayPoints > game.homePoints;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _TeamScore(
          teamName: game.homeTeam,
          goals: game.homeGoals,
          behinds: game.homeBehinds,
          points: game.homePoints,
          isWinner: homeWins,
        )),
        Container(
          width: 2,
          height: 80,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        Expanded(child: _TeamScore(
          teamName: game.awayTeam,
          goals: game.awayGoals,
          behinds: game.awayBehinds,
          points: game.awayPoints,
          isWinner: awayWins,
        )),
      ],
    );
  }
}

/// Individual team score display
class _TeamScore extends StatelessWidget {
  final String teamName;
  final int goals;
  final int behinds;
  final int points;
  final bool isWinner;

  const _TeamScore({
    required this.teamName,
    required this.goals,
    required this.behinds,
    required this.points,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? Theme.of(context).colorScheme.primary : null;
    final fontWeight = isWinner ? FontWeight.w600 : null;

    return Column(
      children: [
        AdaptiveTitle(
          title: teamName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: fontWeight,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          minScaleFactor: 0.6,
        ),
        const SizedBox(height: 8),
        Text(
          '$points',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '$goals.$behinds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: fontWeight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Game result badge
class _GameResultBadge extends StatelessWidget {
  final GameRecord game;
  final bool isComplete;

  const _GameResultBadge({
    required this.game,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDraw = game.homePoints == game.awayPoints;
    final homeWins = game.homePoints > game.awayPoints;
    final margin = (game.homePoints - game.awayPoints).abs();

    if (isDraw && game.homePoints == 0) return const SizedBox.shrink();

    String resultText;
    if (isDraw) {
      if (!isComplete) return const SizedBox.shrink();
      resultText = 'Draw';
    } else if (isComplete) {
      resultText = homeWins 
        ? '${game.homeTeam} won by $margin'
        : '${game.awayTeam} won by $margin';
    } else {
      resultText = homeWins 
        ? '${game.homeTeam} leads by $margin'
        : '${game.awayTeam} leads by $margin';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AdaptiveTitle(
        title: resultText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        minScaleFactor: 0.8,
      ),
    );
  }
}

/// Quarter breakdown section
class _QuarterBreakdownSection extends StatelessWidget {
  final GameRecord game;
  final List<GameEvent>? liveEvents;
  final ScorePanelAdapter? scorePanel;

  const _QuarterBreakdownSection({
    required this.game,
    this.liveEvents,
    this.scorePanel,
  });

  @override
  Widget build(BuildContext context) {
    return _GameCard(
      icon: Icons.timeline,
      title: 'Quarter Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamBreakdown(context, game.homeTeam, true),
          const SizedBox(height: 16),
          _buildTeamBreakdown(context, game.awayTeam, false),
        ],
      ),
    );
  }

  Widget _buildTeamBreakdown(BuildContext context, String teamName, bool isHome) {
    final homeWins = game.homePoints > game.awayPoints;
    final awayWins = game.awayPoints > game.homePoints;
    final isWinner = isHome ? homeWins : awayWins;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            teamName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWinner ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
        ScoreTableBuilderService.buildScoreTable(
          context: context,
          game: game,
          displayTeam: teamName,
          isHomeTeam: isHome,
          isLiveData: liveEvents != null,
          liveEvents: liveEvents,
          scorePanelAdapter: scorePanel,
        ),
      ],
    );
  }
}
