import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';
import 'package:goalkeeper/services/share_service.dart';
import 'package:goalkeeper/services/image_service.dart';

/// A full-screen page for displaying game details from history
class GameDetailsPage extends StatefulWidget {
  final GameRecord game;

  const GameDetailsPage({super.key, required this.game});

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.game.homeTeam} vs ${widget.game.awayTeam}'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isSaving ? null : () => _saveToGallery(context),
            tooltip: 'Save to Gallery',
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: GameDetailsWidget.fromStaticData(game: widget.game),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSharing ? null : () => _shareGameDetails(context),
        tooltip: 'Share Game Details',
        child: _isSharing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.share),
      ),
    );
  }

  void _shareGameDetails(BuildContext context) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final shareText = _buildShareText();

      await ShareService.shareWidgetAsImage(
        repaintBoundaryKey: _repaintBoundaryKey,
        context: context,
        shareText: shareText,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _saveToGallery(BuildContext context) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ImageService.saveWidgetToGallery(
        repaintBoundaryKey: _repaintBoundaryKey,
        context: context,
        homeTeam: widget.game.homeTeam,
        awayTeam: widget.game.awayTeam,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildShareText() {
    final homeScore =
        '${widget.game.homeGoals}.${widget.game.homeBehinds} (${widget.game.homePoints})';
    final awayScore =
        '${widget.game.awayGoals}.${widget.game.awayBehinds} (${widget.game.awayPoints})';

    return '''${widget.game.homeTeam} vs ${widget.game.awayTeam}
Score: $homeScore - $awayScore
Date: ${widget.game.date.day}/${widget.game.date.month}/${widget.game.date.year}''';
  }
}
