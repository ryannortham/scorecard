import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/services/scoring_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/scoring/scoring.dart';
import 'package:goalkeeper/widgets/timer/timer.dart';
import 'package:goalkeeper/widgets/game_details/game_details_widget.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

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
  List<bool> isSelected = [true, false, false, false];
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  // Use the decoupled scoring state manager
  final ScoringStateManager _scoringStateManager = ScoringStateManager.instance;
  bool _isClockRunning = false;

  // Share functionality
  final GlobalKey _gameDetailsKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Sync local clock state with provider state
    _isClockRunning = scorePanelProvider.isTimerRunning;

    // Initialize the game if not already started
    if (_scoringStateManager.currentGameId == null) {
      _scoringStateManager.startNewGame();
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
    _scoringStateManager.recordQuarterEnd(quarter);

    // Stop the timer and update provider state
    _isClockRunning = false;
    scorePanelProvider.setTimerRunning(false);

    // If this is the end of quarter 4, handle game completion
    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  // Public method that can be called by score counter when events change
  void updateGameAfterEventChange() {
    // The scoring state manager handles automatic saving
    _scoringStateManager.updateGameAfterEventChange();
  }

  /// Check if the game is completed (Q4 has ended)
  bool _isGameComplete() {
    return _scoringStateManager.isGameComplete();
  }

  /// Handle game completion by navigating back to previous screen
  void _handleGameCompletion() {
    // Only navigate back once when game is complete
    if (_isGameComplete()) {
      // Use post-frame callback to avoid during-build navigation issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Navigate back to previous screen (game history)
        Navigator.of(context).pop();
      });
    }
  }

  // Access game events from the scoring state manager
  List<GameEvent> get gameEvents => _scoringStateManager.gameEvents;

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
      final shareText = _buildShareText();

      // Use post-frame callback to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _shareWithWidgetShotPlus(shareText);
        } catch (e) {
          debugPrint('Error in share post-frame callback: $e');
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
      debugPrint('Error preparing share: $e');
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void saveGameImage(BuildContext context) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Use post-frame callback to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _saveImageToDevice();
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Game image saved to gallery'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error in save post-frame callback: $e');
          // Show error if saving failed
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save image: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error preparing save: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildShareText() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final scorePanelAdapter =
        Provider.of<ScorePanelAdapter>(context, listen: false);

    final homeScore =
        '${scorePanelAdapter.homeGoals}.${scorePanelAdapter.homeBehinds} (${scorePanelAdapter.homePoints})';
    final awayScore =
        '${scorePanelAdapter.awayGoals}.${scorePanelAdapter.awayBehinds} (${scorePanelAdapter.awayPoints})';

    return '''${gameSetupAdapter.homeTeam} vs ${gameSetupAdapter.awayTeam}
Score: $homeScore - $awayScore
Date: ${gameSetupAdapter.gameDate.day}/${gameSetupAdapter.gameDate.month}/${gameSetupAdapter.gameDate.year}''';
  }

  /// Capture and share using WidgetShotPlus
  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      // Create a temporary render context for the widget
      await _forceRenderWidget();

      // Add delay to ensure widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _gameDetailsKey.currentContext?.findRenderObject()
          as WidgetShotPlusRenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find WidgetShotPlus boundary');
      }

      // Capture the full widget content (without scroll controller to avoid errors)
      final imageBytes = await boundary.screenshot(
        format: ShotFormat.png,
        quality: 100,
        pixelRatio: 2.0,
        // Remove scrollController to avoid attachment errors
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
      debugPrint('Error sharing widget: $e');

      // Fallback to text-only sharing
      await Share.share(shareText);

      // No success feedback needed for fallback sharing
    }
  }

  /// Save image to device using WidgetShotPlus
  Future<void> _saveImageToDevice() async {
    try {
      // Create a temporary render context for the widget
      await _forceRenderWidget();

      // Add delay to ensure widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _gameDetailsKey.currentContext?.findRenderObject()
          as WidgetShotPlusRenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find WidgetShotPlus boundary');
      }

      // Capture the full widget content (without scroll controller to avoid errors)
      final imageBytes = await boundary.screenshot(
        format: ShotFormat.png,
        quality: 100,
        pixelRatio: 2.0,
        // Remove scrollController to avoid attachment errors
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture image');
      }

      // Save the image to device gallery using gal package
      final fileName = _generateFileName();

      // Create a temporary file first
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Save to gallery using gal
      await Gal.putImage(file.path);

      // Clean up temporary file
      await file.delete();
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  /// Force render the hidden widget by temporarily making it visible
  Future<void> _forceRenderWidget() async {
    // Trigger a rebuild to ensure the widget is in the widget tree
    if (mounted) {
      setState(() {});
      // Wait for the build to complete
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Generate a descriptive filename for the image
  String _generateFileName() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome =
        gameSetupAdapter.homeTeam.replaceAll(RegExp(r'[^\w]'), '');
    final cleanAway =
        gameSetupAdapter.awayTeam.replaceAll(RegExp(r'[^\w]'), '');
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  Widget _buildGameDetailsContent() {
    return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
      builder: (context, gameSetupProvider, scorePanelProvider, _) {
        // Get the current game events from the scoring state manager
        final ScoringStateManager scoringStateManager =
            ScoringStateManager.instance;
        final List<GameEvent> currentEvents = scoringStateManager.gameEvents;

        // Build a GameRecord from current live data for capture
        final GameRecord gameRecord = GameRecord(
          id: 'current-game',
          date: gameSetupProvider.gameDate,
          homeTeam: gameSetupProvider.homeTeam,
          awayTeam: gameSetupProvider.awayTeam,
          quarterMinutes: gameSetupProvider.quarterMinutes,
          isCountdownTimer: gameSetupProvider.isCountdownTimer,
          events: currentEvents,
          homeGoals: scorePanelProvider.homeGoals,
          homeBehinds: scorePanelProvider.homeBehinds,
          awayGoals: scorePanelProvider.awayGoals,
          awayBehinds: scorePanelProvider.awayBehinds,
        );

        // Wrap in WidgetShotPlus for sharing capability
        return WidgetShotPlus(
          key: _gameDetailsKey,
          child: CaptureableGameDetailsWidget(game: gameRecord),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupAdapter>(
      builder: (context, scorePanelState, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timer Panel Card
                  Card(
                    elevation: 1,
                    child: QuarterTimerPanel(
                        key: _quarterTimerKey, isTimerRunning: isTimerRunning),
                  ),
                  const SizedBox(height: 8),

                  // Home Team Score Table
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, timerRunning, child) {
                      return Consumer<ScorePanelAdapter>(
                        builder: (context, scorePanelAdapter, child) {
                          return Card(
                            elevation: 1,
                            child: ScoreTable(
                              events: List<GameEvent>.from(
                                  gameEvents), // Create a defensive copy
                              homeTeam: homeTeamName,
                              awayTeam: awayTeamName,
                              displayTeam: homeTeamName,
                              isHomeTeam: true,
                              enabled: timerRunning,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Away Team Score Table
                  ValueListenableBuilder<bool>(
                    valueListenable: isTimerRunning,
                    builder: (context, timerRunning, child) {
                      return Consumer<ScorePanelAdapter>(
                        builder: (context, scorePanelAdapter, child) {
                          return Card(
                            elevation: 1,
                            child: ScoreTable(
                              events: List<GameEvent>.from(
                                  gameEvents), // Create a defensive copy
                              homeTeam: homeTeamName,
                              awayTeam: awayTeamName,
                              displayTeam: awayTeamName,
                              isHomeTeam: false,
                              enabled: timerRunning,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Hidden game details widget for screenshot capture
                  // Position it off-screen but still render it
                  Transform.translate(
                    offset: const Offset(-10000, 0),
                    child: Opacity(
                      opacity: 0.01, // Nearly invisible but still rendered
                      child: _buildGameDetailsContent(),
                    ),
                  ),
                ],
              ),
            ),
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
      },
    );
  }
}
