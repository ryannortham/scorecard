import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/services/game_analysis_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/score_table_builder_service.dart';
import 'package:scorecard/widgets/adaptive_title.dart';
import 'package:scorecard/services/asset_icon_service.dart';

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
      return Consumer<GameStateService>(
        builder: (context, gameState, child) {
          final game = _buildLiveGame(gameState);
          return _buildContent(context, game);
        },
      );
    } else {
      return _buildContent(context, staticGame!);
    }
  }

  GameRecord _buildLiveGame(GameStateService gameState) {
    return GameRecord(
      id: 'current-game',
      date: gameState.gameDate,
      homeTeam: gameState.homeTeam,
      awayTeam: gameState.awayTeam,
      quarterMinutes: gameState.quarterMinutes,
      isCountdownTimer: gameState.isCountdownTimer,
      events: liveEvents ?? [],
      homeGoals: gameState.homeGoals,
      homeBehinds: gameState.homeBehinds,
      awayGoals: gameState.awayGoals,
      awayBehinds: gameState.awayBehinds,
    );
  }

  Widget _buildContent(BuildContext context, GameRecord game) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreSection(game: game, isLiveData: isLiveData),
        const SizedBox(height: 16),
        _QuarterBreakdownSection(game: game, liveEvents: liveEvents),
      ],
    );

    if (enableScrolling) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(8.0),
        child: content,
      );
    } else {
      return Padding(padding: const EdgeInsets.all(8.0), child: content);
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
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.primary),
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

/// Score section
class _ScoreSection extends StatelessWidget {
  final GameRecord game;
  final bool isLiveData;

  const _ScoreSection({required this.game, required this.isLiveData});

  @override
  Widget build(BuildContext context) {
    final isComplete = GameAnalysisService.isGameComplete(game);
    final title = _getScoreTitle(isComplete);

    // Get trophy icon if game is complete and favorite team won
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final shouldShowTrophy = GameAnalysisService.shouldShowTrophyIcon(
      game,
      userPrefs,
    );
    final icon =
        shouldShowTrophy ? Icons.emoji_events_outlined : Icons.outlined_flag;

    return _GameCard(
      icon: icon,
      title: title,
      child: Column(
        children: [
          _TeamScoresRow(game: game),
          const SizedBox(height: 16),
          _GameResultBadge(game: game, isComplete: isComplete),
          const SizedBox(height: 12),
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(game.date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getScoreTitle(bool isComplete) {
    if (isLiveData) {
      final gameState = GameStateService.instance;
      final quarter = gameState.selectedQuarter;
      final timeMs = gameState.getElapsedTimeInQuarter();
      final timeStr = StopWatchTimer.getDisplayTime(
        timeMs,
        hours: false,
        milliSecond: true,
      );
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

    return Stack(
      children: [
        // Background team logos (watermarks)
        Row(
          children: [
            Expanded(child: _TeamLogoWatermark(teamName: game.homeTeam)),
            const SizedBox(width: 18),
            Expanded(child: _TeamLogoWatermark(teamName: game.awayTeam)),
          ],
        ),
        // Foreground content with proper alignment
        Column(
          children: [
            // Team names row
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _TeamName(
                      teamName: game.homeTeam,
                      isWinner: homeWins,
                    ),
                  ),
                  const SizedBox(width: 18), // Space for divider + padding
                  Expanded(
                    child: _TeamName(
                      teamName: game.awayTeam,
                      isWinner: awayWins,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Scores row
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TeamScores(
                      goals: game.homeGoals,
                      behinds: game.homeBehinds,
                      points: game.homePoints,
                      isWinner: homeWins,
                    ),
                  ),
                  const SizedBox(width: 18), // Same width as top spacing
                  Expanded(
                    child: _TeamScores(
                      goals: game.awayGoals,
                      behinds: game.awayBehinds,
                      points: game.awayPoints,
                      isWinner: awayWins,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Overlaid vertical divider
        Positioned.fill(
          child: Center(
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: Container(
                width: 2,
                color: ColorService.withAlpha(context.colors.outline, 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Team name display widget
class _TeamName extends StatelessWidget {
  final String teamName;
  final bool isWinner;

  const _TeamName({required this.teamName, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? context.colors.primary : null;
    final fontWeight = isWinner ? FontWeight.w600 : null;

    return Text(
      teamName,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: color, fontWeight: fontWeight),
      textAlign: TextAlign.center,
      maxLines: null,
      overflow: TextOverflow.visible,
    );
  }
}

/// Team scores display widget
class _TeamScores extends StatelessWidget {
  final int goals;
  final int behinds;
  final int points;
  final bool isWinner;

  const _TeamScores({
    required this.goals,
    required this.behinds,
    required this.points,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? context.colors.primary : null;
    final fontWeight = isWinner ? FontWeight.w600 : null;

    return Column(
      children: [
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

  const _GameResultBadge({required this.game, required this.isComplete});

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
      resultText =
          homeWins
              ? '${game.homeTeam} won by $margin'
              : '${game.awayTeam} won by $margin';
    } else {
      resultText =
          homeWins
              ? '${game.homeTeam} leads by $margin'
              : '${game.awayTeam} leads by $margin';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        resultText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.colors.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }
}

/// Quarter breakdown section
class _QuarterBreakdownSection extends StatelessWidget {
  final GameRecord game;
  final List<GameEvent>? liveEvents;

  const _QuarterBreakdownSection({required this.game, this.liveEvents});

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

  Widget _buildTeamBreakdown(
    BuildContext context,
    String teamName,
    bool isHome,
  ) {
    final homeWins = game.homePoints > game.awayPoints;
    final awayWins = game.awayPoints > game.homePoints;
    final isWinner = isHome ? homeWins : awayWins;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Consumer<TeamsProvider>(
                builder: (context, teamsProvider, child) {
                  final team = teamsProvider.findTeamByName(teamName);
                  // Use logoUrl32 for 32x32 display, with fallbacks
                  final logoUrl =
                      team?.logoUrl32 ?? team?.logoUrl48 ?? team?.logoUrl;

                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    child:
                        logoUrl != null && logoUrl.isNotEmpty
                            ? ClipOval(
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorService.withAlpha(
                                        context.colors.outline,
                                        0.5,
                                      ),
                                    ),
                                    child: FootballIcon(
                                      size: 16,
                                      color: ColorService.withAlpha(
                                        context.colors.outline,
                                        0.6,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorService.withAlpha(
                                  context.colors.outline,
                                  0.1,
                                ),
                              ),
                              child: FootballIcon(
                                size: 16,
                                color: ColorService.withAlpha(
                                  context.colors.outline,
                                  0.6,
                                ),
                              ),
                            ),
                  );
                },
              ),
              Expanded(
                child: Text(
                  teamName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWinner ? context.colors.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        ScoreTableBuilderService.buildScoreTable(
          context: context,
          game: game,
          displayTeam: teamName,
          isHomeTeam: isHome,
          isLiveData: liveEvents != null,
          liveEvents: liveEvents,
        ),
      ],
    );
  }
}

/// Team logo watermark widget
class _TeamLogoWatermark extends StatelessWidget {
  final String teamName;

  const _TeamLogoWatermark({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        final team = teamsProvider.findTeamByName(teamName);
        // Use logoUrlLarge for watermarks, with fallbacks
        final logoUrl = team?.logoUrlLarge ?? team?.logoUrl48 ?? team?.logoUrl;

        return Center(
          child: Opacity(
            opacity: 0.2, // Subtle watermark opacity
            child: SizedBox(
              width: 144,
              height: 144,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: const [0.0, 0.4, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child:
                    logoUrl != null && logoUrl.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            logoUrl, // Use the logo URL directly - teams should be imported with larger logos
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackLogo(context);
                            },
                          ),
                        )
                        : _buildFallbackLogo(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorService.withAlpha(context.colors.outline, 0.1),
      ),
      child: FootballIcon(
        size: 72,
        color: ColorService.withAlpha(context.colors.outline, 0.3),
      ),
    );
  }
}
