import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/widgets/game_setup/game_settings_configuration.dart';
import 'package:scorecard/widgets/game_setup/team_selection_widget.dart';
import 'package:scorecard/widgets/menu/app_menu.dart';
import 'package:scorecard/services/asset_icon_service.dart';

import 'scoring_screen.dart';
import 'package:scorecard/services/color_service.dart';

/// Scoring setup screen that serves as the game setup interface
class ScoringSetupScreen extends StatefulWidget {
  const ScoringSetupScreen({super.key});

  @override
  State<ScoringSetupScreen> createState() => _ScoringSetupScreenState();
}

class _ScoringSetupScreenState extends State<ScoringSetupScreen> {
  String? homeTeam;
  String? awayTeam;
  bool _hasInitialized = false;

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
    // Set up the date controller with today's date
    _dateController.text = DateFormat('EEEE dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once, and only after user preferences are loaded
    if (!_hasInitialized) {
      final userPreferences = Provider.of<UserPreferencesProvider>(
        context,
        listen: true, // Listen for changes
      );

      // Wait for user preferences to be loaded before initializing
      if (userPreferences.loaded) {
        // Defer initialization until after the build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initializeGameState();
          }
        });
        _hasInitialized = true;
      }
    }
  }

  void _initializeGameState() {
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

    // Set up the form fields
    String homeTeamValue = '';
    if (userPreferences.favoriteTeam.isNotEmpty) {
      homeTeamValue = userPreferences.favoriteTeam;
    }

    setState(() {
      homeTeam = homeTeamValue.isNotEmpty ? homeTeamValue : null;
      awayTeam = null;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPreferencesProvider>(
      builder: (context, userPreferences, child) {
        // Show loading screen until settings are loaded
        if (!userPreferences.loaded) {
          return const Scaffold(
            extendBody: true,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<GameStateService>(
          builder: (context, gameState, child) {
            return Scaffold(
              extendBody: true,
              body: Stack(
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
                            context.colors.primaryContainer,
                            context.colors.primaryContainer,
                            ColorService.withAlpha(
                              context.colors.primaryContainer,
                              0.9,
                            ),
                            context.colors.surface,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main content with collapsible app bar
                  NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverAppBar(
                          backgroundColor: context.colors.primaryContainer,
                          foregroundColor: context.colors.onPrimaryContainer,
                          floating: true,
                          snap: true,
                          pinned: false,
                          elevation: 0,
                          shadowColor: ColorService.transparent,
                          surfaceTintColor: ColorService.transparent,
                          automaticallyImplyLeading:
                              false, // Remove back button
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FootballIcon(
                                size: 48,
                                color: context.colors.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Footy Score Card',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          actions: [const AppMenu(currentRoute: 'game_setup')],
                        ),
                      ];
                    },
                    body: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableHeight =
                                  MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).padding.top -
                                  kToolbarHeight;

                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: availableHeight - 16.0,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          // Teams Section
                                          Card(
                                            elevation: 0,
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Text(
                                                        'Teams',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  TeamSelectionWidget(
                                                    homeTeam: homeTeam,
                                                    awayTeam: awayTeam,
                                                    onHomeTeamChanged: (
                                                      newTeam,
                                                    ) {
                                                      setState(() {
                                                        homeTeam = newTeam;
                                                      });
                                                      // Also update the game state immediately
                                                      gameState.configureGame(
                                                        homeTeam: newTeam ?? '',
                                                        awayTeam:
                                                            gameState.awayTeam,
                                                        gameDate:
                                                            gameState.gameDate,
                                                        quarterMinutes:
                                                            gameState
                                                                .quarterMinutes,
                                                        isCountdownTimer:
                                                            gameState
                                                                .isCountdownTimer,
                                                      );
                                                    },
                                                    onAwayTeamChanged: (
                                                      newTeam,
                                                    ) {
                                                      setState(() {
                                                        awayTeam = newTeam;
                                                      });
                                                      // Also update the game state immediately
                                                      gameState.configureGame(
                                                        homeTeam:
                                                            gameState.homeTeam,
                                                        awayTeam: newTeam ?? '',
                                                        gameDate:
                                                            gameState.gameDate,
                                                        quarterMinutes:
                                                            gameState
                                                                .quarterMinutes,
                                                        isCountdownTimer:
                                                            gameState
                                                                .isCountdownTimer,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // Game Date Section
                                          Card(
                                            elevation: 0,
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Game Date',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Form(
                                                    key: dateKey,
                                                    child: TextFormField(
                                                      readOnly: true,
                                                      controller:
                                                          _dateController,
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodyLarge,
                                                      decoration:
                                                          const InputDecoration(
                                                            border:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Please select Game Date';
                                                        }
                                                        return null;
                                                      },
                                                      onTap: () async {
                                                        final DateTime?
                                                        pickedDate = await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              DateTime.now(),
                                                          firstDate: DateTime.now()
                                                              .subtract(
                                                                const Duration(
                                                                  days: 365,
                                                                ),
                                                              ),
                                                          lastDate:
                                                              DateTime.now().add(
                                                                const Duration(
                                                                  days: 365,
                                                                ),
                                                              ),
                                                        );

                                                        if (pickedDate !=
                                                            null) {
                                                          gameState.configureGame(
                                                            homeTeam:
                                                                gameState
                                                                    .homeTeam,
                                                            awayTeam:
                                                                gameState
                                                                    .awayTeam,
                                                            gameDate:
                                                                pickedDate,
                                                            quarterMinutes:
                                                                gameState
                                                                    .quarterMinutes,
                                                            isCountdownTimer:
                                                                gameState
                                                                    .isCountdownTimer,
                                                          );
                                                          _dateController
                                                              .text = DateFormat(
                                                            'EEEE dd/MM/yyyy',
                                                          ).format(pickedDate);
                                                        }
                                                        dateKey.currentState
                                                            ?.validate();
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // Quarter Minutes Section
                                          Card(
                                            elevation: 0,
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child:
                                                  GameSettingsConfiguration(),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.6,
                                            child: FilledButton.icon(
                                              onPressed:
                                                  isValidSetup()
                                                      ? () {
                                                        final gameState =
                                                            Provider.of<
                                                              GameStateService
                                                            >(
                                                              context,
                                                              listen: false,
                                                            );
                                                        // First configure the game with current setup data
                                                        gameState.configureGame(
                                                          homeTeam:
                                                              homeTeam ?? '',
                                                          awayTeam:
                                                              awayTeam ?? '',
                                                          gameDate:
                                                              gameState
                                                                  .gameDate,
                                                          quarterMinutes:
                                                              gameState
                                                                  .quarterMinutes,
                                                          isCountdownTimer:
                                                              gameState
                                                                  .isCountdownTimer,
                                                        );

                                                        // Configure timer settings using current game state values
                                                        gameState.configureTimer(
                                                          isCountdownMode:
                                                              gameState
                                                                  .isCountdownTimer,
                                                          quarterMaxTime:
                                                              gameState
                                                                  .quarterMinutes *
                                                              60 *
                                                              1000,
                                                        );

                                                        // Then reset the score state for a new game
                                                        gameState.resetGame();

                                                        Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => const ScoringScreen(
                                                                  title:
                                                                      'Scoring',
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                      : null,
                                              icon: const Icon(
                                                Icons.outlined_flag,
                                              ),
                                              label: const Text(
                                                'Start Scoring',
                                              ),
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
