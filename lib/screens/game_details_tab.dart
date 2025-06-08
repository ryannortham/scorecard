import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';

/// Legacy GameDetailsTab - now delegates to the reusable GameDetailsWidget
class GameDetailsTab extends StatelessWidget {
  final GameRecord? game;

  const GameDetailsTab({super.key, this.game});

  @override
  Widget build(BuildContext context) {
    if (game != null) {
      // Use static data from provided game
      return GameDetailsWidget.fromStaticData(game: game!);
    } else {
      // Use live data from providers (for current game)
      // Note: events would need to be passed in from parent context
      return const GameDetailsWidget.fromLiveData(events: []);
    }
  }
}
