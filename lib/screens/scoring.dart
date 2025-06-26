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
import 'package:scorecard/widgets/timer/timer_widget.dart';
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
  final GameStateService _gameStateService = GameStateService.instance;

  // Screenshot functionality
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  bool _isSharing = false;

  // Timer key for TimerWidget
  final GlobalKey _quarterTimerKey = GlobalKey();

  // Game events list
  List<GameEvent> get gameEvents => _gameStateService.gameEvents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Initialize the game if not already started
    if (_gameStateService.currentGameId == null) {
      _gameStateService.startNewGame();
    }
  }

  @override
  void initState() {
    super.initState();
    isTimerRunning.addListener(_onTimerRunningChanged);
  }

  void _onTimerRunningChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scorePanelProvider.setTimerRunning(isTimerRunning.value);
      });
    }
  }

  /// Record end of quarter event
  void recordQuarterEnd(int quarter) {
    _gameStateService.recordQuarterEnd(quarter);
    scorePanelProvider.setTimerRunning(false);

    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  /// Handle game completion by navigating to game details screen
  void _handleGameCompletion() {
    if (!_gameStateService.isGameComplete()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final gameId = _gameStateService.currentGameId;
      if (gameId == null) {
        AppLogger.warning(
          'No current game ID found. Cannot navigate to game details',
          component: 'Scoring',
        );
        return;
      }

      await _gameStateService.forceFinalSave();

      final allGames = await GameHistoryService.loadGames();
      final gameRecord = allGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () {
          AppLogger.warning(
            'Could not find game with ID $gameId, using fallback search',
            component: 'Scoring',
            data:
                '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}',
          );
          return allGames.firstWhere(
            (game) =>
                game.homeTeam == gameSetupProvider.homeTeam &&
                game.awayTeam == gameSetupProvider.awayTeam,
          );
        },
      );

      _gameStateService.resetGame();

      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameDetailsPage(game: gameRecord),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    isTimerRunning.dispose();
    super.dispose();
  }

  /// Handle back button behavior with confirmation dialog
  Future<bool> _onWillPop() async {
    if (!mounted) return false;

    final result = await ExitGameBottomSheet.show(context);
    return result;
  }

  /// Show error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _shareGameDetails() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      if (kDebugMode) {
        try {
          await _saveImageInDebugMode();
        } catch (e) {
          AppLogger.error(
            'Failed to save image locally',
            component: 'Scoring',
            error: e,
          );
        }
      }

      final shareText = _buildShareText();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _shareWithWidgetShotPlus(shareText);
        } catch (e) {
          AppLogger.error('Error sharing', component: 'Scoring', error: e);
          _showErrorMessage('Failed to share: $e');
        } finally {
          if (mounted) setState(() => _isSharing = false);
        }
      });
    } catch (e) {
      AppLogger.error('Error preparing share', component: 'Scoring', error: e);
      if (mounted) {
        setState(() => _isSharing = false);
        _showErrorMessage('Failed to prepare share: $e');
      }
    }
  }

  /// Capture screenshot from widget
  Future<Uint8List> _captureScreenshot() async {
    final boundary =
        _screenshotWidgetKey.currentContext?.findRenderObject()
            as WidgetShotPlusRenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Could not find WidgetShotPlus boundary');
    }

    final imageBytes = await boundary.screenshot(
      format: ShotFormat.png,
      quality: 100,
      pixelRatio: 2.0,
    );

    if (imageBytes == null) {
      throw Exception('Failed to capture image');
    }

    return imageBytes;
  }

  /// Capture and share using WidgetShotPlus
  Future<void> _shareWithWidgetShotPlus(String shareText) async {
    try {
      final imageBytes = await _captureScreenshot();

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
      final imageBytes = await _captureScreenshot();

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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanHome = gameSetupProvider.homeTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    final cleanAway = gameSetupProvider.awayTeam.replaceAll(
      RegExp(r'[^\w]'),
      '',
    );
    return '${cleanHome}_v_${cleanAway}_$timestamp.png';
  }

  String _buildShareText() {
    final homeScore =
        '${scorePanelProvider.homeGoals}.${scorePanelProvider.homeBehinds} (${scorePanelProvider.homePoints})';
    final awayScore =
        '${scorePanelProvider.awayGoals}.${scorePanelProvider.awayBehinds} (${scorePanelProvider.awayPoints})';

    return '''${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}
Score: $homeScore - $awayScore
Date: ${gameSetupProvider.gameDate.day}/${gameSetupProvider.gameDate.month}/${gameSetupProvider.gameDate.year}''';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
        drawerEnableOpenDragGesture: true,
        appBar: AppBar(
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          title: AdaptiveTitle(
            title:
                '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}',
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
              onPressed: _isSharing ? null : _shareGameDetails,
            ),
          ],
        ),
        drawer: const AppDrawer(currentRoute: 'scoring'),
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Timer Panel Card
                    Card(
                      elevation: 0,
                      child: TimerWidget(
                        key: _quarterTimerKey,
                        isRunning: isTimerRunning,
                      ),
                    ),

                    // Home Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return ScorePanel(
                          events: List<GameEvent>.from(gameEvents),
                          homeTeam: gameSetupProvider.homeTeam,
                          awayTeam: gameSetupProvider.awayTeam,
                          displayTeam: gameSetupProvider.homeTeam,
                          isHomeTeam: true,
                          enabled: timerRunning,
                        );
                      },
                    ),

                    // Away Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return ScorePanel(
                          events: List<GameEvent>.from(gameEvents),
                          homeTeam: gameSetupProvider.homeTeam,
                          awayTeam: gameSetupProvider.awayTeam,
                          displayTeam: gameSetupProvider.awayTeam,
                          isHomeTeam: false,
                          enabled: timerRunning,
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
      ),
    );
  }
}
