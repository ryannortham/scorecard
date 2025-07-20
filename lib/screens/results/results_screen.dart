import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_analysis_service.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/widgets/menu/app_menu.dart';

import 'package:scorecard/widgets/results/results_widget.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'dart:math';

/// A full-screen page for displaying game details from results
class ResultsScreen extends StatefulWidget {
  final GameRecord game;

  const ResultsScreen({super.key, required this.game});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey _widgetShotKey = GlobalKey();
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  bool _isSharing = false;

  // Confetti controller for celebration
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );

    // Trigger confetti if conditions are met
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerConfetti();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Check if confetti should be triggered and trigger it
  void _checkAndTriggerConfetti() {
    if (_hasTriggeredConfetti) return;

    final userPrefs = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );

    // Check if the game is complete and favorite team won
    final isComplete = GameAnalysisService.isGameComplete(widget.game);
    final shouldShowTrophy = GameAnalysisService.shouldShowTrophyIcon(
      widget.game,
      userPrefs,
    );

    if (isComplete && shouldShowTrophy) {
      _triggerConfetti();
      _hasTriggeredConfetti = true;
    }
  }

  /// Trigger confetti celebration
  void _triggerConfetti() {
    // Single confetti explosion from center
    _confettiController.play();

    AppLogger.info(
      'Confetti triggered for favorite team victory',
      component: 'GameDetails',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.12, 0.25, 0.5],
                  colors: [
                    context.colors.primaryContainer,
                    context.colors.primaryContainer,
                    ColorService.withAlpha(
                      context.colors.primaryContainer,
                      0.9,
                    ),
                    context.colors.surface,
                  ],
                ),
              ),
            ),
          ),

          // Main content with collapsible app bar
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: context.colors.primaryContainer,
                  foregroundColor: context.colors.onPrimaryContainer,
                  floating: true,
                  snap: true,
                  pinned: false,
                  elevation: 0,
                  shadowColor: ColorService.transparent,
                  surfaceTintColor: ColorService.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_outlined),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text("Results"),
                  actions: [
                    IconButton(
                      icon:
                          _isSharing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.share_outlined),
                      onPressed:
                          _isSharing ? null : () => _shareGameDetails(context),
                      tooltip: 'Share Game Details',
                    ),
                    const AppMenu(currentRoute: 'game_details'),
                  ],
                ),
              ];
            },
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: WidgetShotPlus(
                      key: _widgetShotKey,
                      child: ResultsWidget.fromStaticData(
                        game: widget.game,
                        enableScrolling: true,
                      ),
                    ),
                  ),
                ),
              ],
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
                    child: ResultsWidget.fromStaticData(
                      game: widget.game,
                      enableScrolling: false,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Confetti widget for celebration - single explosion from center bottom
          Positioned(
            bottom: 100,
            left: MediaQuery.of(context).size.width * 0.5 - 10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2, // Straight up
              particleDrag: 0.02, // Less drag for higher travel
              emissionFrequency: 0.1, // Quick burst
              numberOfParticles: 20,
              gravity: 0.1, // Higher gravity for quicker fall
              shouldLoop: false,
              minBlastForce: 24, // Higher force for more height
              maxBlastForce: 48,
              maximumSize: const Size(16, 16), // Medium-sized particles
              minimumSize: const Size(8, 8),
              colors: [
                context.colors.primary,
                context.colors.secondary,
                context.colors.tertiary,
                ColorService.getThemeColor('pink'),
                ColorService.getThemeColor('purple'),
              ],
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
                backgroundColor: context.colors.error,
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

  String _buildShareText() {
    return 'Game Results';
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
