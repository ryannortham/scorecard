// lightweight game summary for efficient list display

/// Lightweight game summary containing only essential data for list display.
///
/// Use this instead of `GameRecord` when displaying game lists to avoid
/// loading full event data for each game.
class GameSummary {
  GameSummary({
    required this.id,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.homeBehinds,
    required this.awayGoals,
    required this.awayBehinds,
  });

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      homeGoals: json['homeGoals'] as int,
      homeBehinds: json['homeBehinds'] as int,
      awayGoals: json['awayGoals'] as int,
      awayBehinds: json['awayBehinds'] as int,
    );
  }

  final String id;
  final DateTime date;
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int homeBehinds;
  final int awayGoals;
  final int awayBehinds;

  int get homePoints => homeGoals * 6 + homeBehinds;
  int get awayPoints => awayGoals * 6 + awayBehinds;
}
