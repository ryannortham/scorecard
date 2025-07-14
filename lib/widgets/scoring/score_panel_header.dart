import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/services/game_state_service.dart';
import 'package:scorecard/models/score_models.dart';
import 'package:scorecard/providers/teams_provider.dart';
import 'package:scorecard/widgets/adaptive_title.dart';
import '../../services/asset_icon_service.dart';
import 'package:scorecard/services/color_service.dart';

/// Header widget displaying team name and total score
class ScorePanelHeader extends StatelessWidget {
  final String teamName;
  final bool isHomeTeam;

  const ScorePanelHeader({
    super.key,
    required this.teamName,
    required this.isHomeTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        // Look up the team object to get the logo
        final team = teamsProvider.findTeamByName(teamName);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            children: [
              // Team logo
              _buildTeamLogo(team),
              const SizedBox(width: 8),
              // Team name
              Expanded(
                child: AdaptiveTitle(
                  title: teamName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.primary,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 16),
              Consumer<GameStateService>(
                builder: (context, gameStateService, _) {
                  final goals = gameStateService.getScore(isHomeTeam, true);
                  final behinds = gameStateService.getScore(isHomeTeam, false);
                  final points = goals * 6 + behinds;

                  return Text(
                    points.toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build team logo widget (32x32 size for compact header)
  Widget _buildTeamLogo(Team? team) {
    final logoUrl = team?.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildDefaultLogo();
  }

  /// Build default logo when no team logo is available
  Widget _buildDefaultLogo() {
    return Builder(
      builder:
          (context) => Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: FootballIcon(
              size: 20,
              color: context.colors.onPrimaryContainer,
            ),
          ),
    );
  }
}
