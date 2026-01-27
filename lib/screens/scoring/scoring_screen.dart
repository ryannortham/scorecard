// main scoring screen with timer and score panels

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/models/game_record.dart';
import 'package:scorecard/repositories/game_repository.dart';
import 'package:scorecard/screens/results/results_screen.dart';
import 'package:scorecard/services/dialog_service.dart';
import 'package:scorecard/services/game_sharing_service.dart';
import 'package:scorecard/services/logger_service.dart';
import 'package:scorecard/services/snackbar_service.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/results/results_display.dart';
import 'package:scorecard/widgets/scoring/scoring.dart';
import 'package:scorecard/widgets/timer/timer_display.dart';
import 'package:widget_screenshot_plus/widget_screenshot_plus.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({required this.title, super.key});
  final String title;

  @override
  ScoringScreenState createState() => ScoringScreenState();
}

class ScoringScreenState extends State<ScoringScreen> {
  late GameViewModel gameStateService;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);

  // Screenshot functionality
  final GlobalKey _screenshotWidgetKey = GlobalKey();
  bool _isSharing = false;
  late GameSharingService _gameSharingService;

  // Timer key for TimerDisplay
  final GlobalKey _quarterTimerKey = GlobalKey();

  // Game events list
  List<GameEvent> get gameEvents => gameStateService.gameEvents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameStateService = Provider.of<GameViewModel>(context);

    // Initialize sharing service
    _gameSharingService = GameSharingService(
      screenshotWidgetKey: _screenshotWidgetKey,
      homeTeam: gameStateService.homeTeam,
      awayTeam: gameStateService.awayTeam,
    );

    // Initialize the game if not already started
    if (gameStateService.currentGameId == null) {
      unawaited(gameStateService.startNewGame());
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
        gameStateService.setTimerRunning(isRunning: isTimerRunning.value);
      });
    }
  }

  /// records end of quarter event
  void recordQuarterEnd(int quarter) {
    gameStateService
      ..recordQuarterEnd(quarter)
      ..setTimerRunning(isRunning: false);

    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  /// handles game completion by navigating to results
  void _handleGameCompletion() {
    if (!gameStateService.isGameComplete()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final gameId = gameStateService.currentGameId;
      if (gameId == null) {
        AppLogger.warning(
          'No current game ID found. Cannot navigate to game details',
          component: 'Scoring',
        );
        return;
      }

      final gameRepository = context.read<GameRepository>();
      await gameStateService.forceFinalSave();

      final gameRecord = await gameRepository.loadGameById(gameId);

      if (gameRecord == null) {
        AppLogger.warning(
          'Could not find game with ID $gameId after save',
          component: 'Scoring',
          data: '${gameStateService.homeTeam} vs ${gameStateService.awayTeam}',
        );
        return;
      }

      gameStateService.resetGame();

      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
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

  /// handles back button with confirmation dialog
  Future<bool> _onWillPop() async {
    if (!mounted) return false;

    // Check if there are any game events recorded (any activity including timer/quarter events)
    final hasGameActivity = gameStateService.gameEvents.isNotEmpty;

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

  /// shows error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      SnackBarService.showError(context, message);
    }
  }

  Future<void> _shareGameDetails() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      await _gameSharingService.shareGameDetails();
    } on Exception catch (e) {
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
                      child: ResultsDisplay.fromLiveData(
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
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: TimerDisplay(
                key: _quarterTimerKey,
                isRunning: isTimerRunning,
                onQuarterEnd: recordQuarterEnd,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Home Team Score Table
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildHomeScorePanel(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 6)),

          // Away Team Score Table
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildSliverAppBar(BuildContext context) {
    return StyledSliverAppBar.withBackButton(
      title: Text('Score Card', style: Theme.of(context).textTheme.titleLarge),
      onBackPressed: () async {
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
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

  /// builds home team score panel
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

  /// builds away team score panel
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
