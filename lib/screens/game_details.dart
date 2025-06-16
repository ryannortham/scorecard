import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/app_logger.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

/// A full-screen page for displaying game details from history
class GameDetailsPage extends StatefulWidget {
  final GameRecord game;

  const GameDetailsPage({super.key, required this.game});

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  final GlobalKey _widgetShotKey = GlobalKey();
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      body: Stack(
        children: [
          WidgetShotPlus(
            key: _widgetShotKey,
            child: GameDetailsWidget.fromStaticData(
              game: widget.game,
              scrollController: _scrollController,
            ),
          ),
          // Screenshot widget positioned off-screen
          Positioned(
            left: -1000,
            top: -1000,
            child: WidgetShotPlus(
              key: _screenshotWidgetKey,
              child: Material(
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: 400,
                    child: GameDetailsWidget.fromStaticData(
                      game: widget.game,
                      enableScrolling: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

      // Use post-frame callback to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _shareWithWidgetShotPlus(shareText);
        } catch (e) {
          AppLogger.error('Error in share post-frame callback',
              component: 'GameDetails', error: e);
          // Show error if sharing failed
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to share: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSharing = false;
            });
          }
        }
      });
    } catch (e) {
      AppLogger.error('Error preparing share',
          component: 'GameDetails', error: e);
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _saveToGallery(BuildContext context) async {
    // Prevent multiple save operations at once
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Use a post-frame callback to ensure layout is complete
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Capture the full widget using WidgetShotPlus
          await _saveWithWidgetShotPlus();
        } catch (e) {
          AppLogger.error('Error in _saveToGallery post-frame callback',
              component: 'GameDetails', error: e);
          // Show error message if save fails
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save screenshot: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          // Ensure we restore the state
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      });
    } catch (e) {
      // Handle any synchronous errors
      AppLogger.error('Error setting up post-frame callback',
          component: 'GameDetails', error: e);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare screenshot: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
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

  /// Capture and share using WidgetShotPlus
  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      final boundary = _screenshotWidgetKey.currentContext?.findRenderObject()
          as WidgetShotPlusRenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find WidgetShotPlus boundary');
      }

      // Capture the screenshot widget (no scroll controller needed)
      final imageBytes = await boundary.screenshot(
        format: ShotFormat.png,
        quality: 100,
        pixelRatio: 2.0,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture image');
      }

      // Create a temporary file for sharing
      final directory = await getTemporaryDirectory();
      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Share the image with text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );

      // No success feedback needed - user can see share dialog
    } catch (e) {
      AppLogger.error('Error sharing widget',
          component: 'GameDetails', error: e);

      // Fallback to text-only sharing
      await Share.share(shareText);

      // No success feedback needed for fallback sharing
    }
  }

  /// Save to gallery using WidgetShotPlus
  Future<void> _saveWithWidgetShotPlus() async {
    try {
      final boundary = _screenshotWidgetKey.currentContext?.findRenderObject()
          as WidgetShotPlusRenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find WidgetShotPlus boundary');
      }

      // Capture the screenshot widget (no scroll controller needed)
      final imageBytes = await boundary.screenshot(
        format: ShotFormat.png,
        quality: 100,
        pixelRatio: 2.0,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture image');
      }

      // Save to gallery using gal
      final fileName = _generateFileName();
      await Gal.putImageBytes(imageBytes, name: fileName);

      // Show success feedback for save operation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Game details saved to gallery!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error saving widget',
          component: 'GameDetails', error: e);
      rethrow; // Re-throw to be handled by caller
    }
  }

  /// Generate a descriptive filename for the image
  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome = widget.game.homeTeam.replaceAll(RegExp(r'[^\w]'), '');
    final cleanAway = widget.game.awayTeam.replaceAll(RegExp(r'[^\w]'), '');
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }
}
