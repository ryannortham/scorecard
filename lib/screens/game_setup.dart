import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/widgets/game_setup/game_settings_configuration.dart';
import 'package:scorecard/widgets/game_setup/team_selection_widget.dart';
import 'package:scorecard/widgets/drawer/app_drawer.dart';
import 'package:scorecard/widgets/drawer/swipe_drawer_wrapper.dart';

import 'scoring.dart';

class GameSetup extends StatefulWidget {
  const GameSetup({super.key, required this.title});
  final String title;

  @override
  State<GameSetup> createState() => _GameSetupState();
}

class _GameSetupState extends State<GameSetup> {
  String? homeTeam;
  String? awayTeam;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final dateKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();

  bool isValidSetup() {
    bool dateValid = dateKey.currentState?.validate() ?? false;
    bool homeTeamValid = homeTeam?.isNotEmpty ?? false;
    bool awayTeamValid = awayTeam?.isNotEmpty ?? false;

    return dateValid && homeTeamValid && awayTeamValid;
  }

  @override
  void initState() {
    super.initState();
    // Completely reset and initialize game state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameStateService>(context, listen: false);
      final userPreferences = Provider.of<UserPreferencesProvider>(
        context,
        listen: false,
      );
      // First, completely reset the game state
      gameState.configureGame(
        homeTeam:
            userPreferences.favoriteTeam.isNotEmpty
                ? userPreferences.favoriteTeam
                : '',
        awayTeam: '',
        gameDate: DateTime.now(),
        quarterMinutes: userPreferences.quarterMinutes,
        isCountdownTimer: userPreferences.isCountdownTimer,
      );

      // Reset the score state as well
      gameState.resetGame();

      // Configure the timer with fresh settings
      gameState.configureTimer(
        isCountdownMode: userPreferences.isCountdownTimer,
        quarterMaxTime: userPreferences.quarterMinutes * 60 * 1000,
      );

      // Now set up the form fields
      String homeTeamValue = '';
      if (userPreferences.favoriteTeam.isNotEmpty) {
        homeTeamValue = userPreferences.favoriteTeam;
        // Home team is already set in configureGame above
      }

      _dateController.text = DateFormat(
        'EEEE dd/MM/yyyy',
      ).format(DateTime.now());

      setState(() {
        homeTeam = homeTeamValue.isNotEmpty ? homeTeamValue : null;
        awayTeam = null;
      });
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu_outlined),
                tooltip: 'Menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: 'game_setup'),
      body: SwipeDrawerWrapper(
        child: Stack(
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
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight - 16.0,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Teams Section
                            Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Teams',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TeamSelectionWidget(
                                      homeTeam: homeTeam,
                                      awayTeam: awayTeam,
                                      onHomeTeamChanged: (newTeam) {
                                        setState(() {
                                          homeTeam = newTeam;
                                        });
                                        // Also update the game state immediately
                                        gameState.configureGame(
                                          homeTeam: newTeam ?? '',
                                          awayTeam: gameState.awayTeam,
                                          gameDate: gameState.gameDate,
                                          quarterMinutes:
                                              gameState.quarterMinutes,
                                          isCountdownTimer:
                                              gameState.isCountdownTimer,
                                        );
                                      },
                                      onAwayTeamChanged: (newTeam) {
                                        setState(() {
                                          awayTeam = newTeam;
                                        });
                                        // Also update the game state immediately
                                        gameState.configureGame(
                                          homeTeam: gameState.homeTeam,
                                          awayTeam: newTeam ?? '',
                                          gameDate: gameState.gameDate,
                                          quarterMinutes:
                                              gameState.quarterMinutes,
                                          isCountdownTimer:
                                              gameState.isCountdownTimer,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Game Date Section
                            Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Game Date',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Form(
                                      key: dateKey,
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: _dateController,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select Game Date';
                                          }
                                          return null;
                                        },
                                        onTap: () async {
                                          final DateTime? pickedDate =
                                              await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime.now()
                                                    .subtract(
                                                      const Duration(days: 365),
                                                    ),
                                                lastDate: DateTime.now().add(
                                                  const Duration(days: 365),
                                                ),
                                              );

                                          if (pickedDate != null) {
                                            gameState.configureGame(
                                              homeTeam: gameState.homeTeam,
                                              awayTeam: gameState.awayTeam,
                                              gameDate: pickedDate,
                                              quarterMinutes:
                                                  gameState.quarterMinutes,
                                              isCountdownTimer:
                                                  gameState.isCountdownTimer,
                                            );
                                            _dateController.text = DateFormat(
                                              'EEEE dd/MM/yyyy',
                                            ).format(pickedDate);
                                          }
                                          dateKey.currentState?.validate();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Quarter Minutes Section
                            Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: GameSettingsConfiguration(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: FilledButton.tonalIcon(
                                onPressed:
                                    isValidSetup()
                                        ? () {
                                          final gameState =
                                              Provider.of<GameStateService>(
                                                context,
                                                listen: false,
                                              );
                                          // First configure the game with current setup data
                                          gameState.configureGame(
                                            homeTeam: homeTeam ?? '',
                                            awayTeam: awayTeam ?? '',
                                            gameDate: gameState.gameDate,
                                            quarterMinutes:
                                                gameState.quarterMinutes,
                                            isCountdownTimer:
                                                gameState.isCountdownTimer,
                                          );

                                          // Configure timer settings using current game state values
                                          gameState.configureTimer(
                                            isCountdownMode:
                                                gameState.isCountdownTimer,
                                            quarterMaxTime:
                                                gameState.quarterMinutes *
                                                60 *
                                                1000,
                                          );

                                          // Then reset the score state for a new game
                                          gameState.resetGame();

                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => const Scoring(
                                                    title: 'Scoring',
                                                  ),
                                            ),
                                          );
                                        }
                                        : null,
                                icon: const Icon(Icons.outlined_flag),
                                label: const Text('Start Scoring'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
