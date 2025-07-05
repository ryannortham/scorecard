import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_history_service.dart';
import 'package:scorecard/widgets/game_setup/app_drawer.dart';
import 'package:scorecard/widgets/bottom_sheets/confirmation_bottom_sheet.dart';
import 'package:scorecard/widgets/game_details/game_details_widget.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        title: Text("Game Results"),
        actions: [
          IconButton(
            icon:
                _isSharing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.share_outlined),
            onPressed: _isSharing ? null : () => _shareGameDetails(context),
            tooltip: 'Share Game Details',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteGame(context),
            tooltip: 'Delete Game',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'game_details'),
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
    );
  }

  void _shareGameDetails(BuildContext context) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // In debug mode, save image locally first
      if (kDebugMode) {
        try {
          await _saveImageInDebugMode();
          AppLogger.debug(
            'Image saved locally before sharing',
            component: 'GameDetails',
          );
        } catch (e) {
          AppLogger.error(
            'Failed to save image locally',
            component: 'GameDetails',
            error: e,
          );
          // Continue with sharing even if save fails in debug mode
        }
      }

      final shareText = _buildShareText();

      // Use post-frame callback to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _shareWithWidgetShotPlus(shareText);
        } catch (e) {
          AppLogger.error(
            'Error in share post-frame callback',
            component: 'GameDetails',
            error: e,
          );
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
      AppLogger.error(
        'Error preparing share',
        component: 'GameDetails',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _deleteGame(BuildContext context) async {
    // Show confirmation bottom sheet
    final shouldDelete = await ConfirmationBottomSheet.show(
      context: context,
      actionText: 'Delete Game',
      actionIcon: Icons.delete_outline,
      isDestructive: true,
      onConfirm: () {}, // The bottom sheet handles navigation internally
    );

    if (shouldDelete && context.mounted) {
      try {
        // Delete the game from storage
        await GameHistoryService.deleteGame(widget.game.id);

        AppLogger.info('Game deleted successfully', component: 'GameDetails');

        // Navigate back to the previous screen with result indicating deletion
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        AppLogger.error(
          'Failed to delete game',
          component: 'GameDetails',
          error: e,
        );

        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete game: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Save image in debug mode (without UI state management)
  Future<void> _saveImageInDebugMode() async {
    try {
      final boundary =
          _screenshotWidgetKey.currentContext?.findRenderObject()
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

      AppLogger.debug(
        'Game details saved to gallery',
        component: 'GameDetails',
      );
    } catch (e) {
      AppLogger.error(
        'Error saving widget',
        component: 'GameDetails',
        error: e,
      );
      rethrow; // Re-throw to be handled by caller
    }
  }

  String _buildShareText() {
    return 'Game Results';
  }

  /// Capture and share using WidgetShotPlus
  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      final boundary =
          _screenshotWidgetKey.currentContext?.findRenderObject()
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
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: shareText),
      );

      // No success feedback needed - user can see share dialog
    } catch (e) {
      AppLogger.error(
        'Error sharing widget',
        component: 'GameDetails',
        error: e,
      );

      // Fallback to text-only sharing
      await SharePlus.instance.share(ShareParams(text: shareText));

      // No success feedback needed for fallback sharing
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
