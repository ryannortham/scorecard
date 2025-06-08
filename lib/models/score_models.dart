import 'package:flutter/material.dart';
import 'package:goalkeeper/theme/theme_extensions.dart';

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
          style: AppTextStyles.teamName(context, isWinner: teamScore.isWinner),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapXS,
        Text(
          '${teamScore.score.goals}.${teamScore.score.behinds}',
          style:
              AppTextStyles.scoreDisplay(context, isWinner: teamScore.isWinner)
                  .copyWith(fontSize: fontSize),
          textAlign: TextAlign.center,
        ),
        if (showPoints) ...[
          AppSpacing.gapXS,
          Text(
            '(${teamScore.score.points})',
            style: AppTextStyles.pointsDisplay(context,
                isWinner: teamScore.isWinner),
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
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            CompactScoreDisplay(teamScore: teamScore),
            if (additionalInfo != null) ...[
              AppSpacing.gapMD,
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
          AppSpacing.gapMD,
          Text(
            'vs',
            style: AppTextStyles.subtitle(context),
          ),
          AppSpacing.gapMD,
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
