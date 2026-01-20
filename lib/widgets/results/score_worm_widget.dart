import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/score_worm_data_service.dart';
import 'package:scorecard/widgets/team_logo.dart';

/// Score worm chart widget displaying score differential over time
class ScoreWormWidget extends StatelessWidget {
  final GameRecord? staticGame;
  final List<GameEvent>? liveEvents;
  final bool isLiveData;

  const ScoreWormWidget._({
    super.key,
    this.staticGame,
    this.liveEvents,
    required this.isLiveData,
  });

  /// Factory constructor for static data (completed games)
  const ScoreWormWidget.fromStaticData({Key? key, required GameRecord game})
    : this._(key: key, staticGame: game, liveEvents: null, isLiveData: false);

  /// Factory constructor for live data (current game)
  const ScoreWormWidget.fromLiveData({
    Key? key,
    required List<GameEvent> events,
  }) : this._(key: key, staticGame: null, liveEvents: events, isLiveData: true);

  @override
  Widget build(BuildContext context) {
    if (isLiveData) {
      return Consumer<GameStateService>(
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

  double _calculateLiveProgress(GameStateService gameState) {
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
    final currentQuarter = _getCurrentQuarter(game);

    final data = ScoreWormDataService.generateData(
      events: game.events,
      homeTeam: game.homeTeam,
      awayTeam: game.awayTeam,
      quarterMinutes: game.quarterMinutes,
      liveGameProgress: liveProgress,
    );

    final tickValues = ScoreWormDataService.generateTickValues(data.yAxisMax);

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
            _ScoreWormLayout(
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

  int _getCurrentQuarter(GameRecord game) {
    if (isLiveData) {
      return GameStateService.instance.selectedQuarter;
    }
    if (game.events.isEmpty) return 1;
    return game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
  }
}

/// Score worm layout using Row/Column structure
class _ScoreWormLayout extends StatelessWidget {
  final ScoreWormData data;
  final ScoreWormColours colours;
  final List<int> tickValues;
  final String homeTeam;
  final String awayTeam;
  final int currentQuarter;
  final bool isLiveData;

  // Layout constants
  static const double _logoWidth = 36.0;
  static const double _logoSpacing = 8.0;
  static const double _yAxisWidth = 24.0;
  static const double _chartHeight = 140.0;

  const _ScoreWormLayout({
    required this.data,
    required this.colours,
    required this.tickValues,
    required this.homeTeam,
    required this.awayTeam,
    required this.currentQuarter,
    required this.isLiveData,
  });

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
                          child: Center(child: _TeamLogo(teamName: homeTeam)),
                        ),
                        Expanded(
                          child: Center(child: _TeamLogo(teamName: awayTeam)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _logoSpacing),
                  Expanded(child: _ChartArea(data: data, colours: colours)),
                  SizedBox(
                    width: _yAxisWidth,
                    child: _YAxisLabels(tickValues: tickValues),
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
    // left: logo + spacing, right: y-axis width
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

/// Team logo widget
class _TeamLogo extends StatelessWidget {
  final String teamName;

  const _TeamLogo({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        final team = teamsProvider.findTeamByName(teamName);
        final logoUrl = team?.logoUrl32 ?? team?.logoUrl48 ?? team?.logoUrl;
        return TeamLogo(logoUrl: logoUrl, size: 32);
      },
    );
  }
}

/// Positions labels at gridline heights
class _YAxisLabels extends StatelessWidget {
  final List<int> tickValues;

  const _YAxisLabels({required this.tickValues});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
      fontSize: 10,
    );

    // Labels align with gridline positions: 0%, 25%, 50%, 75%, 100% of height
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final positions = [0.0, 0.25, 0.5, 0.75, 1.0];

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(tickValues.length, (index) {
            final y = positions[index] * height;
            return Positioned(
              top: y - 6,
              left: 8,
              child: Text(tickValues[index].abs().toString(), style: textStyle),
            );
          }),
        );
      },
    );
  }
}

/// Chart area with grid and worm line overlay
class _ChartArea extends StatelessWidget {
  final ScoreWormData data;
  final ScoreWormColours colours;

  const _ChartArea({required this.data, required this.colours});

  @override
  Widget build(BuildContext context) {
    final gridColour = context.colors.outline.withValues(alpha: 0.2);
    final zeroLineColour = context.colors.outline.withValues(alpha: 0.5);
    final watermarkStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: context.colors.outline.withValues(alpha: 0.15),
      fontWeight: FontWeight.bold,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: _GridPainter(
            gridColour: gridColour,
            zeroLineColour: zeroLineColour,
          ),
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Center(
                  child: Text('Q${index + 1}', style: watermarkStyle),
                ),
              );
            }),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _WormLinePainter(
              points: data.points,
              yAxisMax: data.yAxisMax,
              colours: colours,
            ),
          ),
        ),
      ],
    );
  }
}

/// Grid painter for chart background
class _GridPainter extends CustomPainter {
  final Color gridColour;
  final Color zeroLineColour;

  _GridPainter({required this.gridColour, required this.zeroLineColour});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = gridColour
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final zeroLinePaint =
        Paint()
          ..color = zeroLineColour
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // horizontal lines at 25%, 50%, 75%
    final quarterHeight = size.height / 4;
    canvas.drawLine(
      Offset(0, quarterHeight),
      Offset(size.width, quarterHeight),
      paint,
    );
    // zero line (heavier)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      zeroLinePaint,
    );
    canvas.drawLine(
      Offset(0, quarterHeight * 3),
      Offset(size.width, quarterHeight * 3),
      paint,
    );

    // vertical lines for quarter columns
    final colWidth = size.width / 4;
    for (int i = 1; i < 4; i++) {
      final x = i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridColour != gridColour ||
        oldDelegate.zeroLineColour != zeroLineColour;
  }
}

/// Worm line painter with zero-crossing colour changes
class _WormLinePainter extends CustomPainter {
  final List<ScoreWormPoint> points;
  final int yAxisMax;
  final ScoreWormColours colours;

  _WormLinePainter({
    required this.points,
    required this.yAxisMax,
    required this.colours,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint =
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

    Offset toScreen(double x, int differential) {
      final screenX = (x / 4.0) * size.width;
      final screenY =
          size.height / 2 - (differential / yAxisMax) * (size.height / 2);
      return Offset(screenX, screenY);
    }

    Color getColour(int differential) {
      if (differential > 0) return colours.homeLeadingColour;
      if (differential < 0) return colours.awayLeadingColour;
      return colours.neutralColour;
    }

    // draw line segments, splitting at zero crossings
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final crossesZero =
          (p1.differential > 0 && p2.differential < 0) ||
          (p1.differential < 0 && p2.differential > 0);

      if (crossesZero && p1.differential != 0 && p2.differential != 0) {
        // interpolate to find zero crossing point
        final t =
            p1.differential.abs() /
            (p1.differential.abs() + p2.differential.abs());
        final zeroX = p1.x + t * (p2.x - p1.x);

        // first half in p1's colour
        paint.color = getColour(p1.differential);
        canvas.drawLine(
          toScreen(p1.x, p1.differential),
          toScreen(zeroX, 0),
          paint,
        );

        // second half in p2's colour
        paint.color = getColour(p2.differential);
        canvas.drawLine(
          toScreen(zeroX, 0),
          toScreen(p2.x, p2.differential),
          paint,
        );
      } else {
        // no crossing - use the non-zero differential's colour
        final colourDiff =
            p1.differential != 0 ? p1.differential : p2.differential;
        paint.color = getColour(colourDiff);
        canvas.drawLine(
          toScreen(p1.x, p1.differential),
          toScreen(p2.x, p2.differential),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WormLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.yAxisMax != yAxisMax ||
        oldDelegate.colours != colours;
  }
}
