// unified results widget for displaying game details from static or live data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/widgets/results/quarter_breakdown_section.dart';
import 'package:scorecard/widgets/results/score_section.dart';
import 'package:scorecard/widgets/results/score_worm.dart';

/// unified widget for displaying game details
class ResultsDisplay extends StatelessWidget {
  const ResultsDisplay({
    super.key,
    this.staticGame,
    this.liveEvents,
    this.scrollController,
    this.enableScrolling = true,
  }) : isLiveData = staticGame == null;

  /// factory constructor for static data (game results)
  const ResultsDisplay.fromStaticData({
    required GameRecord game,
    super.key,
    this.scrollController,
    this.enableScrolling = true,
  }) : staticGame = game,
       liveEvents = null,
       isLiveData = false;

  /// factory constructor for live data (current game)
  const ResultsDisplay.fromLiveData({
    required List<GameEvent> events,
    super.key,
    this.scrollController,
    this.enableScrolling = true,
  }) : staticGame = null,
       liveEvents = events,
       isLiveData = true;
  final GameRecord? staticGame;
  final List<GameEvent>? liveEvents;
  final ScrollController? scrollController;
  final bool enableScrolling;
  final bool isLiveData;

  @override
  Widget build(BuildContext context) {
    if (isLiveData) {
      return Consumer<GameViewModel>(
        builder: (context, gameState, child) {
          final game = _buildLiveGame(gameState);
          return _buildContent(context, game);
        },
      );
    } else {
      return _buildContent(context, staticGame!);
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

  Widget _buildContent(BuildContext context, GameRecord game) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScoreSection(game: game, isLiveData: isLiveData),
        const SizedBox(height: 4),
        if (isLiveData)
          ScoreWorm.fromLiveData(events: liveEvents ?? [])
        else
          ScoreWorm.fromStaticData(game: game),
        const SizedBox(height: 4),
        QuarterBreakdownSection(game: game, liveEvents: liveEvents),
      ],
    );

    if (enableScrolling) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: 4,
          right: 4,
          top: 4,
          bottom: 4.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: content,
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(
          left: 4,
          right: 4,
          top: 4,
          bottom: 4.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: content,
      );
    }
  }
}
