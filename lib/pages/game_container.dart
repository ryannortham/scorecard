import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/settings_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/pages/scoring_tab.dart';
import 'package:goalkeeper/pages/game_details.dart';
import 'settings.dart';

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScoringTabState> _scoringTabKey =
      GlobalKey<ScoringTabState>();

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
    // If we're on the scoring tab, delegate to the scoring tab's exit logic
    if (_currentIndex == 0 && _scoringTabKey.currentState != null) {
      return await _scoringTabKey.currentState!.handleExit();
    }

    return await _showExitConfirmation();
  }

  Widget _buildGameDetailsWrapper() {
    return Consumer3<GameSetupProvider, ScorePanelProvider, GameSetupProvider>(
      builder: (context, gameSetupProvider, scorePanelProvider, _, __) {
        // Get the current game events from the scoring tab
        final List<GameEvent> currentEvents =
            _scoringTabKey.currentState?.gameEvents ?? [];

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
        appBar: AppBar(
          title: Text(
              '${gameSetupProvider.homeTeam} vs ${gameSetupProvider.awayTeam}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Menu',
              onPressed: () async {
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
                  gameSetupProvider.setQuarterMinutes(
                      settingsProvider.defaultQuarterMinutes);
                  gameSetupProvider.setIsCountdownTimer(
                      settingsProvider.defaultIsCountdownTimer);
                }
              },
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            ScoringTab(key: _scoringTabKey),
            _buildGameDetailsWrapper(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.calculator),
              label: 'Scoring',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.circleInfo),
              label: 'Details',
            ),
          ],
        ),
      ),
    );
  }
}
