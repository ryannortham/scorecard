import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';

import 'package:scorecard/adapters/game_setup_adapter.dart';
import 'package:scorecard/adapters/score_panel_adapter.dart';
import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/game_history_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/game_sharing_service.dart';
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
  late GameSharingService _gameSharingService;

  // Timer key for TimerWidget
  final GlobalKey _quarterTimerKey = GlobalKey();

  // Game events list
  List<GameEvent> get gameEvents => _gameStateService.gameEvents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Initialize sharing service
    _gameSharingService = GameSharingService(
      screenshotWidgetKey: _screenshotWidgetKey,
      gameSetupProvider: gameSetupProvider,
      scorePanelProvider: scorePanelProvider,
    );

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
      await _gameSharingService.shareGameDetails();
    } catch (e) {
      AppLogger.error(
        'Error sharing game details',
        component: 'Scoring',
        error: e,
      );
      _showErrorMessage('Failed to share: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
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
                  children: [
                    // Timer Panel
                    TimerWidget(
                      key: _quarterTimerKey,
                      isRunning: isTimerRunning,
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
