import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';

import 'package:scorecard/providers/game_record.dart';
import 'package:scorecard/services/app_logger.dart';
import 'package:scorecard/services/color_service.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/results_service.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/services/game_sharing_service.dart';
import 'package:scorecard/widgets/app_scaffold.dart';
import 'package:scorecard/widgets/scoring/scoring.dart';
import 'package:scorecard/widgets/timer/timer_widget.dart';
import 'package:scorecard/widgets/results/results_widget.dart';
import 'package:scorecard/widgets/menu/app_menu.dart';

import '../results/results_screen.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key, required this.title});
  final String title;

  @override
  ScoringScreenState createState() => ScoringScreenState();
}

class ScoringScreenState extends State<ScoringScreen> {
  late GameStateService gameStateService;
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
    gameStateService = Provider.of<GameStateService>(context);

    // Initialize sharing service
    _gameSharingService = GameSharingService(
      screenshotWidgetKey: _screenshotWidgetKey,
      gameStateService: gameStateService,
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
        gameStateService.setTimerRunning(isTimerRunning.value);
      });
    }
  }

  /// Record end of quarter event
  void recordQuarterEnd(int quarter) {
    _gameStateService.recordQuarterEnd(quarter);
    gameStateService.setTimerRunning(false);

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

      final allGames = await ResultsService.loadGames();
      final gameRecord = allGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () {
          AppLogger.warning(
            'Could not find game with ID $gameId, using fallback search',
            component: 'Scoring',
            data:
                '${gameStateService.homeTeam} vs ${gameStateService.awayTeam}',
          );
          return allGames.firstWhere(
            (game) =>
                game.homeTeam == gameStateService.homeTeam &&
                game.awayTeam == gameStateService.awayTeam,
          );
        },
      );

      _gameStateService.resetGame();

      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultsScreen(game: gameRecord),
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

    // Check if there are any game events recorded (any activity including timer/quarter events)
    final hasGameActivity = _gameStateService.gameEvents.isNotEmpty;

    // If no game activity, allow exit without confirmation
    if (!hasGameActivity) {
      return true;
    }

    // Show confirmation dialog if there's any game activity
    final result = await DialogService.showConfirmationDialog(
      context: context,
      title: '',
      content: '',
      confirmText: 'Exit Game?',
      isDestructive: true,
    );
    return result;
  }

  /// Show error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: context.colors.error),
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
      child: AppScaffold(
        body: Stack(
          children: [
            _buildScrollableLayout(context),

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
                      child: ResultsWidget.fromLiveData(
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
  }

  Widget _buildScrollableLayout(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [_buildSliverAppBar(context)];
      },
      body: CustomScrollView(
        slivers: [
          // Timer Panel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
              child: TimerWidget(
                key: _quarterTimerKey,
                isRunning: isTimerRunning,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Home Team Score Table
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildHomeScorePanel(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Away Team Score Table
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildAwayScorePanel(),
            ),
          ),

          // Bottom padding for safe scrolling
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: ColorService.transparent,
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
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text("Score Card", style: Theme.of(context).textTheme.titleLarge),
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
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
      const AppMenu(currentRoute: 'scoring'),
    ];
  }

  /// Build home team score panel with ValueListenableBuilder
  Widget _buildHomeScorePanel() {
    return ValueListenableBuilder<bool>(
      valueListenable: isTimerRunning,
      builder: (context, timerRunning, child) {
        return ScorePanel(
          events: List<GameEvent>.from(gameEvents),
          homeTeam: gameStateService.homeTeam,
          awayTeam: gameStateService.awayTeam,
          displayTeam: gameStateService.homeTeam,
          isHomeTeam: true,
          enabled: timerRunning,
        );
      },
    );
  }

  /// Build away team score panel with ValueListenableBuilder
  Widget _buildAwayScorePanel() {
    return ValueListenableBuilder<bool>(
      valueListenable: isTimerRunning,
      builder: (context, timerRunning, child) {
        return ScorePanel(
          events: List<GameEvent>.from(gameEvents),
          homeTeam: gameStateService.homeTeam,
          awayTeam: gameStateService.awayTeam,
          displayTeam: gameStateService.awayTeam,
          isHomeTeam: false,
          enabled: timerRunning,
        );
      },
    );
  }
}
