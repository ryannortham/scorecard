import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';
import 'package:goalkeeper/services/share_service.dart';

/// A full-screen page for displaying game details from history
class GameDetailsPage extends StatelessWidget {
  final GameRecord game;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  GameDetailsPage({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${game.homeTeam} vs ${game.awayTeam}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareGameDetails(context),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: GameDetailsWidget.fromStaticData(game: game),
      ),
    );
  }

  void _shareGameDetails(BuildContext context) {
    final shareText = _buildShareText();

    ShareService.shareWidgetAsImage(
      repaintBoundaryKey: _repaintBoundaryKey,
      context: context,
      shareText: shareText,
    );
  }

  String _buildShareText() {
    final homeScore =
        '${game.homeGoals}.${game.homeBehinds} (${game.homePoints})';
    final awayScore =
        '${game.awayGoals}.${game.awayBehinds} (${game.awayPoints})';

    return '''${game.homeTeam} vs ${game.awayTeam}
Score: $homeScore - $awayScore
Date: ${game.date.day}/${game.date.month}/${game.date.year}''';
  }
}
