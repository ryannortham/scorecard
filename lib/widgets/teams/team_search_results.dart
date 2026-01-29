// displays search results for teams with loading, error, and empty states

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:scorecard/extensions/string_extensions.dart';
import 'package:scorecard/models/playhq.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/widgets/common/football_icon.dart';

/// constants for team search ui
class TeamSearchConstants {
  static const double logoSize = 48;
  static const double defaultLogoIconSize = 28;
  static const double largeIconSize = 64;
  static const double circularProgressStrokeWidth = 2;
  static const double paddingSmall = 4;
  static const double paddingMedium = 8;
}

/// displays search results for teams including loading, error, and empty states
class TeamSearchResults extends StatelessWidget {
  const TeamSearchResults({
    required this.hasSearched,
    required this.isLoading,
    required this.errorMessage,
    required this.searchResults,
    required this.searchQuery,
    required this.onTeamTap,
    required this.onRetry,
    super.key,
  });

  final bool hasSearched;
  final bool isLoading;
  final String? errorMessage;
  final List<Organisation> searchResults;
  final String searchQuery;
  final void Function(Organisation team) onTeamTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: TeamSearchConstants.largeIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: TeamSearchConstants.paddingMedium),
            Text('Searching teams...', style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: TeamSearchConstants.largeIconSize,
              color: colorScheme.error,
            ),
            const SizedBox(height: TeamSearchConstants.paddingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TeamSearchConstants.paddingMedium,
              ),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
            ),
            const SizedBox(height: TeamSearchConstants.paddingMedium),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FootballIcon(
              size: TeamSearchConstants.largeIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: TeamSearchConstants.paddingMedium),
            Text(
              'No teams found for "$searchQuery"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TeamSearchConstants.paddingSmall),
            Text(
              'Try a different search term',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TeamSearchConstants.paddingMedium),
      itemCount: searchResults.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Fixed item height improves scroll performance
      itemExtent: 72,
      itemBuilder: (context, index) {
        final team = searchResults[index];
        return _TeamSearchCard(team: team, onTap: () => onTeamTap(team));
      },
    );
  }
}

/// card displaying a team from search results
class _TeamSearchCard extends StatelessWidget {
  const _TeamSearchCard({required this.team, required this.onTap});

  final Organisation team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final processedName = team.name.toProcessedTeamName();

    return Card(
      margin: const EdgeInsets.only(bottom: TeamSearchConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(TeamSearchConstants.paddingMedium),
        leading: _TeamSearchLogo(team: team),
        title: Text(
          processedName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// displays a team logo from search results with loading and error states
class _TeamSearchLogo extends StatelessWidget {
  const _TeamSearchLogo({required this.team});

  final Organisation team;

  @override
  Widget build(BuildContext context) {
    final logoUrl = team.logoUrlLarge ?? team.logoUrl48;

    if (logoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: TeamSearchConstants.logoSize,
          height: TeamSearchConstants.logoSize,
          fit: BoxFit.cover,
          // Limit decoded image size in memory cache (2x for retina)
          memCacheWidth: (TeamSearchConstants.logoSize * 2).toInt(),
          memCacheHeight: (TeamSearchConstants.logoSize * 2).toInt(),
          placeholder:
              (context, url) => const SizedBox(
                width: TeamSearchConstants.logoSize,
                height: TeamSearchConstants.logoSize,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth:
                        TeamSearchConstants.circularProgressStrokeWidth,
                  ),
                ),
              ),
          errorWidget: (context, url, error) => _buildDefaultLogo(context),
        ),
      );
    }

    return _buildDefaultLogo(context);
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return Container(
      width: TeamSearchConstants.logoSize,
      height: TeamSearchConstants.logoSize,
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: FootballIcon(
        size: TeamSearchConstants.defaultLogoIconSize,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }
}
