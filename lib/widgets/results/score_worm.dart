// score worm chart widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/models/score_worm.dart';
import 'package:scorecard/services/score_worm_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/widgets/results/score_worm_components.dart';

/// displays score differential over time
class ScoreWorm extends StatelessWidget {
  const ScoreWorm._({
    required this.isLiveData,
    super.key,
    this.staticGame,
    this.liveEvents,
  });

  /// factory constructor for static data (completed games)
  const ScoreWorm.fromStaticData({required GameRecord game, Key? key})
    : this._(key: key, staticGame: game, liveEvents: null, isLiveData: false);

  /// factory constructor for live data (current game)
  const ScoreWorm.fromLiveData({
    required List<GameEvent> events,
    Key? key,
  }) : this._(key: key, staticGame: null, liveEvents: events, isLiveData: true);
  final GameRecord? staticGame;
  final List<GameEvent>? liveEvents;
  final bool isLiveData;

  @override
  Widget build(BuildContext context) {
    if (isLiveData) {
      return Consumer<GameViewModel>(
        builder: (context, gameState, child) {
          final game = _buildLiveGame(gameState);
          final liveProgress = _calculateLiveProgress(gameState);
          return _buildContent(context, game, liveProgress);
        },
      );
    } else {
      return _buildContent(context, staticGame!, null);
    }
  }

  GameRecord _buildLiveGame(GameViewModel gameState) {
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

  double _calculateLiveProgress(GameViewModel gameState) {
    final quarter = gameState.selectedQuarter;
    final elapsedMs = gameState.getElapsedTimeInQuarter();
    final quarterMs = gameState.quarterMSec;

    final quarterProgress = (elapsedMs / quarterMs).clamp(0.0, 1.0);
    return (quarter - 1) + quarterProgress;
  }

  Widget _buildContent(
    BuildContext context,
    GameRecord game,
    double? liveProgress,
  ) {
    final colours = ScoreWormColours.fromTheme(context.colors);
    final currentQuarter = _getCurrentQuarter(context, game);

    final data = ScoreWormService.generateData(
      events: game.events,
      homeTeam: game.homeTeam,
      awayTeam: game.awayTeam,
      quarterMinutes: game.quarterMinutes,
      liveGameProgress: liveProgress,
    );

    final tickValues = ScoreWormService.generateTickValues(data.yAxisMax);

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Score Worm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ScoreWormLayoutInternal(
              data: data,
              colours: colours,
              tickValues: tickValues,
              homeTeam: game.homeTeam,
              awayTeam: game.awayTeam,
              currentQuarter: currentQuarter,
              isLiveData: isLiveData,
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentQuarter(BuildContext context, GameRecord game) {
    if (isLiveData) {
      return context.read<GameViewModel>().selectedQuarter;
    }
    if (game.events.isEmpty) return 1;
    return game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
  }
}

/// score worm layout using row/column structure
class _ScoreWormLayoutInternal extends StatelessWidget {
  const _ScoreWormLayoutInternal({
    required this.data,
    required this.colours,
    required this.tickValues,
    required this.homeTeam,
    required this.awayTeam,
    required this.currentQuarter,
    required this.isLiveData,
  });
  final ScoreWormData data;
  final ScoreWormColours colours;
  final List<int> tickValues;
  final String homeTeam;
  final String awayTeam;
  final int currentQuarter;
  final bool isLiveData;

  static const double _logoWidth = 36;
  static const double _logoSpacing = 8;
  static const double _yAxisWidth = 24;
  static const double _chartHeight = 140;

  @override
  Widget build(BuildContext context) {
    final scoreStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);

    return Column(
      children: [
        _buildScoreRow(context, data.homeQuarterScores, scoreStyle),
        const SizedBox(height: 4),
        SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _logoWidth,
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ScoreWormTeamLogo(teamName: homeTeam),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ScoreWormTeamLogo(teamName: awayTeam),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _logoSpacing),
                  Expanded(
                    child: ScoreWormChartArea(data: data, colours: colours),
                  ),
                  SizedBox(
                    width: _yAxisWidth,
                    child: ScoreWormYAxisLabels(tickValues: tickValues),
                  ),
                ],
              ),
              // zero line extending through logo area
              Positioned(
                left: 0,
                right: _yAxisWidth,
                top: _chartHeight / 2 - 0.75,
                child: Container(
                  height: 1.5,
                  color: context.colors.outline.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _buildScoreRow(context, data.awayQuarterScores, scoreStyle),
      ],
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    Map<int, QuarterScore> quarterScores,
    TextStyle? style,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: _logoWidth + _logoSpacing,
        right: _yAxisWidth,
      ),
      child: Row(
        children: List.generate(4, (index) {
          final quarter = index + 1;
          final score = quarterScores[quarter] ?? QuarterScore.zero;
          final isFutureQuarter = isLiveData && quarter > currentQuarter;

          return Expanded(
            child: Text(
              isFutureQuarter ? '' : score.display,
              textAlign: TextAlign.center,
              style: style,
            ),
          );
        }),
      ),
    );
  }
}
