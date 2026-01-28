// scoring setup screen for game configuration

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/game_view_model.dart';
import 'package:scorecard/viewmodels/preferences_view_model.dart';
import 'package:scorecard/widgets/common/app_menu.dart';
import 'package:scorecard/widgets/common/app_scaffold.dart';
import 'package:scorecard/widgets/common/football_icon.dart';
import 'package:scorecard/widgets/common/styled_sliver_app_bar.dart';
import 'package:scorecard/widgets/scoring_setup/date_card.dart';
import 'package:scorecard/widgets/scoring_setup/start_scoring_fab.dart';
import 'package:scorecard/widgets/scoring_setup/teams_card.dart';
import 'package:scorecard/widgets/scoring_setup/timer_config.dart';

/// game setup interface
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
  final _dateKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  bool get isValidSetup {
    final dateValid = _dateKey.currentState?.validate() ?? false;
    final homeTeamValid = homeTeam?.isNotEmpty ?? false;
    final awayTeamValid = awayTeam?.isNotEmpty ?? false;
    return dateValid && homeTeamValid && awayTeamValid;
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('EEEE dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      final userPreferences = Provider.of<PreferencesViewModel>(context);

      if (userPreferences.loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _initializeGameState();
        });
        _hasInitialized = true;
      }
    }
  }

  void _initializeGameState() {
    final gameState = Provider.of<GameViewModel>(context, listen: false);
    final userPreferences = Provider.of<PreferencesViewModel>(
      context,
      listen: false,
    );

    final initialHomeTeam = userPreferences.getDefaultFavoriteTeam() ?? '';

    gameState
      ..configureGame(
        homeTeam: initialHomeTeam,
        awayTeam: '',
        gameDate: DateTime.now(),
        quarterMinutes: userPreferences.quarterMinutes,
        isCountdownTimer: userPreferences.isCountdownTimer,
      )
      ..resetGame()
      ..configureTimer(
        isCountdownMode: userPreferences.isCountdownTimer,
        quarterMaxTime: userPreferences.quarterMinutes * 60 * 1000,
      );

    setState(() {
      homeTeam = initialHomeTeam.isNotEmpty ? initialHomeTeam : null;
      awayTeam = null;
    });
  }

  /// updates a single field in game configuration
  void _updateGameConfig(
    GameViewModel gameState, {
    String? homeTeam,
    String? awayTeam,
    DateTime? gameDate,
  }) {
    gameState.configureGame(
      homeTeam: homeTeam ?? gameState.homeTeam,
      awayTeam: awayTeam ?? gameState.awayTeam,
      gameDate: gameDate ?? gameState.gameDate,
      quarterMinutes: gameState.quarterMinutes,
      isCountdownTimer: gameState.isCountdownTimer,
    );
  }

  void _startScoring() {
    final gameState = Provider.of<GameViewModel>(context, listen: false);

    _updateGameConfig(
      gameState,
      homeTeam: homeTeam ?? '',
      awayTeam: awayTeam ?? '',
    );

    gameState
      ..configureTimer(
        isCountdownMode: gameState.isCountdownTimer,
        quarterMaxTime: gameState.quarterMinutes * 60 * 1000,
      )
      ..resetGame();

    unawaited(context.push('/scoring-game'));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesViewModel>(
      builder: (context, userPreferences, child) {
        if (!userPreferences.loaded) {
          return const Scaffold(
            extendBody: true,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<GameViewModel>(
          builder: (context, gameState, child) {
            return AppScaffold(
              extendBody: true,
              body: Stack(
                children: [
                  NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [_buildAppBar(context)];
                    },
                    body: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildFormContent(context, gameState),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StartScoringFab(
                    isEnabled: isValidSetup,
                    onPressed: isValidSetup ? _startScoring : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return StyledSliverAppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FootballIcon(size: 48, color: context.colors.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            'Footy Score Card',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      actions: const [AppMenu(currentRoute: 'game_setup')],
    );
  }

  Widget _buildFormContent(BuildContext context, GameViewModel gameState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            kToolbarHeight;

        return Padding(
          padding: const EdgeInsets.all(4),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight - 16.0),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TeamsCard(
                      homeTeam: homeTeam,
                      awayTeam: awayTeam,
                      onHomeTeamChanged: (newTeam) {
                        setState(() => homeTeam = newTeam);
                        _updateGameConfig(gameState, homeTeam: newTeam ?? '');
                      },
                      onAwayTeamChanged: (newTeam) {
                        setState(() => awayTeam = newTeam);
                        _updateGameConfig(gameState, awayTeam: newTeam ?? '');
                      },
                    ),
                    const SizedBox(height: 4),
                    DateCard(
                      dateController: _dateController,
                      formKey: _dateKey,
                      onDateSelected: (pickedDate) {
                        _updateGameConfig(gameState, gameDate: pickedDate);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildTimerCard(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(padding: EdgeInsets.all(16), child: TimerConfig()),
    );
  }
}
