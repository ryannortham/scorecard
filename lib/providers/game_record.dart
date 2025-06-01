class GameEvent {
  final int quarter;
  final Duration time;
  final String team;
  final String type; // 'goal' or 'behind'

  GameEvent({
    required this.quarter,
    required this.time,
    required this.team,
    required this.type,
  });
}

class GameRecord {
  final DateTime date;
  final String homeTeam;
  final String awayTeam;
  final int quarterMinutes;
  final bool isCountdownTimer;
  final List<GameEvent> events;

  GameRecord({
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.quarterMinutes,
    required this.isCountdownTimer,
    required this.events,
  });
}
