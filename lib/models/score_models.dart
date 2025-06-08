import 'package:flutter/material.dart';

/// Base class for score-related data
class ScoreData {
  final int goals;
  final int behinds;
  final int points;

  const ScoreData({
    required this.goals,
    required this.behinds,
  }) : points = goals * 6 + behinds;

  ScoreData copyWith({
    int? goals,
    int? behinds,
  }) {
    return ScoreData(
      goals: goals ?? this.goals,
      behinds: behinds ?? this.behinds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoreData &&
        other.goals == goals &&
        other.behinds == behinds;
  }

  @override
  int get hashCode => Object.hash(goals, behinds);

  @override
  String toString() => '$goals.$behinds ($points)';
}

/// Team data with score information
class TeamScore {
  final String name;
  final ScoreData score;
  final bool isWinner;

  const TeamScore({
    required this.name,
    required this.score,
    this.isWinner = false,
  });

  TeamScore copyWith({
    String? name,
    ScoreData? score,
    bool? isWinner,
  }) {
    return TeamScore(
      name: name ?? this.name,
      score: score ?? this.score,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}

/// Compact score display widget
class CompactScoreDisplay extends StatelessWidget {
  final TeamScore teamScore;
  final bool showPoints;
  final double? fontSize;

  const CompactScoreDisplay({
    super.key,
    required this.teamScore,
    this.showPoints = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          teamScore.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: teamScore.isWinner
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight:
                    teamScore.isWinner ? FontWeight.w600 : FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${teamScore.score.goals}.${teamScore.score.behinds}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: teamScore.isWinner
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
          textAlign: TextAlign.center,
        ),
        if (showPoints) ...[
          const SizedBox(height: 4),
          Text(
            '(${teamScore.score.points})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: teamScore.isWinner
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: teamScore.isWinner ? FontWeight.w600 : null,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Expanded score display with more details
class DetailedScoreDisplay extends StatelessWidget {
  final TeamScore teamScore;
  final Widget? additionalInfo;

  const DetailedScoreDisplay({
    super.key,
    required this.teamScore,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CompactScoreDisplay(teamScore: teamScore),
            if (additionalInfo != null) ...[
              const SizedBox(height: 16),
              additionalInfo!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying match summary
class MatchSummary extends StatelessWidget {
  final TeamScore homeTeam;
  final TeamScore awayTeam;
  final bool showVersus;
  final bool compact;

  const MatchSummary({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    this.showVersus = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: CompactScoreDisplay(
            teamScore: homeTeam,
            fontSize: compact ? 14.0 : null,
          ),
        ),
        if (showVersus) ...[
          const SizedBox(height: 16, width: 16),
          Text(
            'vs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 16, width: 16),
        ],
        Expanded(
          child: CompactScoreDisplay(
            teamScore: awayTeam,
            fontSize: compact ? 14.0 : null,
          ),
        ),
      ],
    );
  }
}

/// Score comparison helper
class ScoreComparator {
  static bool isWinner(ScoreData team1, ScoreData team2) {
    return team1.points > team2.points;
  }

  static bool isDraw(ScoreData team1, ScoreData team2) {
    return team1.points == team2.points;
  }

  static int pointsDifference(ScoreData winner, ScoreData loser) {
    return winner.points - loser.points;
  }

  static TeamScore determineWinner(TeamScore team1, TeamScore team2) {
    if (team1.score.points > team2.score.points) {
      return team1.copyWith(isWinner: true);
    } else if (team2.score.points > team1.score.points) {
      return team2.copyWith(isWinner: true);
    }
    return team1; // Draw case
  }
}
