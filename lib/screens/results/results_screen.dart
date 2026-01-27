// game results display screen with sharing and confetti

import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/extensions/game_record_extensions.dart';
import 'package:scorecard/providers/game_record_provider.dart';
import 'package:scorecard/providers/preferences_provider.dart';
import 'package:scorecard/services/game_sharing_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/sliver_app_bar.dart';
import 'package:scorecard/widgets/results/results_widget.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';

/// displays game details with sharing and celebration
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({required this.game, super.key});
  final GameRecord game;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey _widgetShotKey = GlobalKey();
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  bool _isSharing = false;
  late GameSharingService _gameSharingService;

  // Confetti controller for celebration
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize sharing service
    _gameSharingService = GameSharingService(
      screenshotWidgetKey: _screenshotWidgetKey,
      homeTeam: widget.game.homeTeam,
      awayTeam: widget.game.awayTeam,
    );

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

  /// checks and triggers confetti for favourite team win
  void _checkAndTriggerConfetti() {
    if (_hasTriggeredConfetti) return;

    final userPrefs = Provider.of<UserPreferencesProvider>(
      context,
      listen: false,
    );

    // Check if the game is complete and favorite team won
    final isComplete = widget.game.isComplete;
    final shouldShowTrophy = widget.game.shouldShowTrophy(userPrefs);

    if (isComplete && shouldShowTrophy) {
      _triggerConfetti();
      _hasTriggeredConfetti = true;
    }
  }

  /// triggers confetti celebration
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
    return AppScaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main content with collapsible app bar
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                AppSliverAppBar.withBackButton(
                  title: const Text('Results'),
                  onBackPressed: () => Navigator.of(context).pop(),
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
                  child: WidgetShotPlus(
                    key: _widgetShotKey,
                    child: ResultsWidget.fromStaticData(
                      game: widget.game,
                    ),
                  ),
                ),

                // Add bottom padding for system navigation bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
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

          // Confetti widget for celebration - explosion from center bottom
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

  Future<void> _shareGameDetails(BuildContext context) async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      await _gameSharingService.shareGameDetails();
    } on Exception catch (e) {
      AppLogger.error(
        'Error sharing game details',
        component: 'GameDetails',
        error: e,
      );
      if (context.mounted) {
        SnackBarService.showError(context, 'Failed to share: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
