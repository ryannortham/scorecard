// game event and record models for persistence

import 'package:uuid/uuid.dart';

/// Represents a single scoring or clock event during a game.
class GameEvent {
  GameEvent({
    required this.quarter,
    required this.time,
    required this.team,
    required this.type,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      quarter: json['quarter'] as int,
      time: Duration(milliseconds: json['timeMs'] as int),
      team: json['team'] as String,
      type: json['type'] as String,
    );
  }

  final int quarter;
  final Duration time;
  final String team; // empty for clock events
  // event types: goal, behind, clock_start, clock_pause, clock_end
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'quarter': quarter,
      'timeMs': time.inMilliseconds,
      'team': team,
      'type': type,
    };
  }
}

/// Complete game record with all events and final scores.
class GameRecord {
  GameRecord({
    required this.id,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    required this.quarterMinutes,
    required this.isCountdownTimer,
    required this.events,
    required this.homeGoals,
    required this.homeBehinds,
    required this.awayGoals,
    required this.awayBehinds,
  });

  /// Creates a new game record with a generated UUID.
  factory GameRecord.create({
    required DateTime date,
    required String homeTeam,
    required String awayTeam,
    required int quarterMinutes,
    required bool isCountdownTimer,
    required List<GameEvent> events,
    required int homeGoals,
    required int homeBehinds,
    required int awayGoals,
    required int awayBehinds,
  }) {
    return GameRecord(
      id: const Uuid().v4(),
      date: date,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      quarterMinutes: quarterMinutes,
      isCountdownTimer: isCountdownTimer,
      events: events,
      homeGoals: homeGoals,
      homeBehinds: homeBehinds,
      awayGoals: awayGoals,
      awayBehinds: awayBehinds,
    );
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      quarterMinutes: json['quarterMinutes'] as int,
      isCountdownTimer: json['isCountdownTimer'] as bool,
      events:
          (json['events'] as List)
              .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
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
  final int quarterMinutes;
  final bool isCountdownTimer;
  final List<GameEvent> events;
  final int homeGoals;
  final int homeBehinds;
  final int awayGoals;
  final int awayBehinds;

  int get homePoints => homeGoals * 6 + homeBehinds;
  int get awayPoints => awayGoals * 6 + awayBehinds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'quarterMinutes': quarterMinutes,
      'isCountdownTimer': isCountdownTimer,
      'events': events.map((e) => e.toJson()).toList(),
      'homeGoals': homeGoals,
      'homeBehinds': homeBehinds,
      'awayGoals': awayGoals,
      'awayBehinds': awayBehinds,
    };
  }
}
