import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_history_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/widgets/adaptive_title.dart';
import 'package:scorecard/widgets/bottom_sheets/exit_game_bottom_sheet.dart';
import 'package:scorecard/widgets/scoring/scoring.dart';
import 'package:scorecard/widgets/timer/timer.dart';
import 'package:scorecard/widgets/game_details/game_details_widget.dart';
import 'package:scorecard/widgets/game_setup/app_drawer.dart';

import 'game_details.dart';

class Scoring extends StatefulWidget {
  const Scoring({super.key, required this.title});
  final String title;

  @override
  ScoringState createState() => ScoringState();
}

class ScoringState extends State<Scoring> {
  late ScorePanelAdapter scorePanelProvider;
  late GameSetupAdapter gameSetupProvider;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  // Use the game state service directly
  final GameStateService _gameStateService = GameStateService.instance;
  bool _isClockRunning = false;

  // Screenshot functionality
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  bool _isSharing = false;

  Future<bool> _showExitConfirmation() async {
    return await ExitGameBottomSheet.show(context);
  }

  Future<bool> _onWillPop() async {
    // Always show exit confirmation when leaving an active game
    return await _showExitConfirmation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Sync local clock state with provider state
    _isClockRunning = scorePanelProvider.isTimerRunning;

    // Initialize the game if not already started
    if (_gameStateService.currentGameId == null) {
      _gameStateService.startNewGame();
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listener to the timer running state to track clock events
    isTimerRunning.addListener(() {
      _onTimerRunningChanged(isTimerRunning.value);
    });
  }

  /// Track timer state changes
  void _onTimerRunningChanged(bool isRunning) {
    // Use post-frame callback to avoid setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isRunning && !_isClockRunning) {
        // Timer started
        _isClockRunning = true;
        scorePanelProvider.setTimerRunning(true);
      } else if (!isRunning && _isClockRunning) {
        // Timer paused
        _isClockRunning = false;
        scorePanelProvider.setTimerRunning(false);
      }
    });
  }

  /// Record end of quarter event
  /// This method is called from the QuarterTimerPanel when quarters change
  /// and from the timer widget when a quarter's time expires
  void recordQuarterEnd(int quarter) {
    _gameStateService.recordQuarterEnd(quarter);

    // Stop the timer and update provider state
    _isClockRunning = false;
    scorePanelProvider.setTimerRunning(false);

    // If this is the end of quarter 4, handle game completion
    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  /// Check if the game is completed (Q4 has ended)
  bool _isGameComplete() {
    return _gameStateService.isGameComplete();
  }

  /// Handle game completion by navigating to game details screen
  void _handleGameCompletion() {
    // Only navigate once when game is complete
    if (_isGameComplete()) {
      // Use post-frame callback to avoid during-build navigation issues
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final String? gameId = _gameStateService.currentGameId;
        if (gameId == null) {
          AppLogger.warning(
            'No current game ID found. Cannot navigate to game details',
            component: 'Scoring',
          );
          return;
        }

        // CRITICAL FIX: Ensure final save completes before resetting
        // Force immediate save of the completed game before resetting state
        await _gameStateService.forceFinalSave();

        // Load all saved games and find the one with the matching ID
        // Since we now preserve the game ID, it should be found reliably
        final allGames = await GameHistoryService.loadGames();
        final gameRecord = allGames.firstWhere(
          (game) => game.id == gameId,
          orElse: () {
            // Fallback: find the most recent game with matching teams
            final homeTeam = gameSetupProvider.homeTeam;
            final awayTeam = gameSetupProvider.awayTeam;
            AppLogger.warning(
              'Could not find game with ID $gameId, using fallback search',
              component: 'Scoring',
              data: '$homeTeam vs $awayTeam',
            );
            return allGames.firstWhere(
              (game) => game.homeTeam == homeTeam && game.awayTeam == awayTeam,
            );
          },
        );

        // Reset the game state AFTER ensuring save is complete
        // Clean state for next game setup
        _gameStateService.resetGame();

        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameDetailsPage(game: gameRecord),
          ),
        );
      });
    }
  }

  // Access game events from the game state service
  List<GameEvent> get gameEvents => _gameStateService.gameEvents;

  @override
  void dispose() {
    isTimerRunning.dispose();
    super.dispose();
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
            component: 'Scoring',
          );
        } catch (e) {
          AppLogger.error(
            'Failed to save image locally',
            component: 'Scoring',
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
            component: 'Scoring',
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
      AppLogger.error('Error preparing share', component: 'Scoring', error: e);
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare share: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

      // Capture the screenshot widget
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
    } catch (e) {
      AppLogger.error('Error sharing widget', component: 'Scoring', error: e);

      // Fallback to text-only sharing
      await SharePlus.instance.share(ShareParams(text: shareText));
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

      // Capture the screenshot widget
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

      AppLogger.debug('Game image saved to gallery', component: 'Scoring');
    } catch (e) {
      AppLogger.error('Error saving widget', component: 'Scoring', error: e);
      rethrow; // Re-throw to be handled by caller
    }
  }

  /// Generate a descriptive filename for the image
  String _generateFileName() {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(
      context,
      listen: false,
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome = gameSetupAdapter.homeTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    final cleanAway = gameSetupAdapter.awayTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  String _buildShareText() {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(
      context,
      listen: false,
    );
    final scorePanelAdapter = Provider.of<ScorePanelAdapter>(
      context,
      listen: false,
    );

    final homeScore =
        '${scorePanelAdapter.homeGoals}.${scorePanelAdapter.homeBehinds} (${scorePanelAdapter.homePoints})';
    final awayScore =
        '${scorePanelAdapter.awayGoals}.${scorePanelAdapter.awayBehinds} (${scorePanelAdapter.awayPoints})';

    return '''${gameSetupAdapter.homeTeam} vs ${gameSetupAdapter.awayTeam}
Score: $homeScore - $awayScore
Date: ${gameSetupAdapter.gameDate.day}/${gameSetupAdapter.gameDate.month}/${gameSetupAdapter.gameDate.year}''';
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Consumer<GameSetupAdapter>(
        builder: (context, scorePanelState, _) {
          return Scaffold(
            drawerEdgeDragWidth:
                MediaQuery.of(context).size.width * 0.75, // 75% of screen width
            drawerEnableOpenDragGesture: true, // Explicitly enable drawer swipe
            appBar: AppBar(
              leading: Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Menu',
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
              ),
              title: AdaptiveTitle(
                title: '$homeTeamName vs $awayTeamName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                  tooltip: 'Share Game Details',
                  onPressed:
                      _isSharing ? null : () => _shareGameDetails(context),
                ),
              ],
            ),
            drawer: const AppDrawer(currentRoute: 'scoring'),
            body: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Timer Panel Card
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surface,
                          child: QuarterTimerPanel(
                            key: _quarterTimerKey,
                            isTimerRunning: isTimerRunning,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Home Team Score Table
                        ValueListenableBuilder<bool>(
                          valueListenable: isTimerRunning,
                          builder: (context, timerRunning, child) {
                            return Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                              child: ScoreTable(
                                events: List<GameEvent>.from(gameEvents),
                                homeTeam: homeTeamName,
                                awayTeam: awayTeamName,
                                displayTeam: homeTeamName,
                                isHomeTeam: true,
                                enabled: timerRunning,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 4),

                        // Away Team Score Table
                        ValueListenableBuilder<bool>(
                          valueListenable: isTimerRunning,
                          builder: (context, timerRunning, child) {
                            return Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                              child: ScoreTable(
                                events: List<GameEvent>.from(gameEvents),
                                homeTeam: homeTeamName,
                                awayTeam: awayTeamName,
                                displayTeam: awayTeamName,
                                isHomeTeam: false,
                                enabled: timerRunning,
                              ),
                            );
                          },
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
                            child: GameDetailsWidget.fromLiveData(
                              events: gameEvents,
                              enableScrolling: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
