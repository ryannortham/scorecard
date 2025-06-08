import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/screens/scoring.dart';
import 'package:goalkeeper/screens/game_details.dart';
import 'package:goalkeeper/widgets/common/custom_app_bar.dart';
import 'settings.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScoringState> _scoringKey = GlobalKey<ScoringState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.exit_to_app_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Exit Game?'),
              content:
                  const Text('Are you sure you want to exit the current game?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    // Always show exit confirmation for now
    // TODO: Could add specific logic for scoring tab if needed
    return await _showExitConfirmation();
  }

  Widget _buildGameDetailsContent() {
    return Consumer3<GameSetupProvider, ScorePanelProvider, GameSetupProvider>(
      builder: (context, gameSetupProvider, scorePanelProvider, _, __) {
        // Get the current game events from the scoring screen
        final List<GameEvent> currentEvents =
            _scoringKey.currentState?.gameEvents ?? [];

        // Create a temporary GameRecord from current state
        final GameRecord currentGame = GameRecord(
          id: 'current-game', // Temporary ID for current game
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

        // Use GameDetailsContent from the GameDetailsPage
        return GameDetailsContent(game: currentGame);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameSetupProvider = Provider.of<GameSetupProvider>(context);

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
        appBar: CustomAppBar(
          title:
              '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}',
          showSettings: true,
          onSettingsPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Settings(title: 'Settings'),
              ),
            );
            // Update game setup with current settings when returning
            if (context.mounted) {
              final settingsProvider =
                  Provider.of<SettingsProvider>(context, listen: false);
              final gameSetupProvider =
                  Provider.of<GameSetupProvider>(context, listen: false);
              gameSetupProvider
                  .setQuarterMinutes(settingsProvider.defaultQuarterMinutes);
              gameSetupProvider.setIsCountdownTimer(
                  settingsProvider.defaultIsCountdownTimer);
            }
          },
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            Scoring(key: _scoringKey, title: 'Scoring'),
            _buildGameDetailsContent(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_score),
              label: 'Scoring',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Details',
            ),
          ],
        ),
      ),
    );
  }
}
