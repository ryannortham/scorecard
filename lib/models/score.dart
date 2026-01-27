// team and score data models for afl scoring

import 'package:flutter/foundation.dart';
import 'package:scorecard/models/playhq.dart';

/// team data with optional logos and address information
@immutable
class Team {
  const Team({
    required this.name,
    this.logoUrl,
    this.logoUrl32,
    this.logoUrl48,
    this.logoUrlLarge,
    this.address,
    this.playHQId,
    this.routingCode,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: (json['name'] as String?) ?? '',
      logoUrl: json['logoUrl'] as String?,
      logoUrl32: json['logoUrl32'] as String?,
      logoUrl48: json['logoUrl48'] as String?,
      logoUrlLarge: json['logoUrlLarge'] as String?,
      address:
          json['address'] != null
              ? Address.fromJson(json['address'] as Map<String, dynamic>)
              : null,
      playHQId: json['playHQId'] as String?,
      routingCode: json['routingCode'] as String?,
    );
  }
  final String name;
  final String? logoUrl;
  final String? logoUrl32;
  final String? logoUrl48;
  final String? logoUrlLarge;
  final Address? address;
  final String? playHQId;
  final String? routingCode;

  Team copyWith({
    String? name,
    String? logoUrl,
    String? logoUrl32,
    String? logoUrl48,
    String? logoUrlLarge,
    Address? address,
    String? playHQId,
    String? routingCode,
  }) {
    return Team(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      logoUrl32: logoUrl32 ?? this.logoUrl32,
      logoUrl48: logoUrl48 ?? this.logoUrl48,
      logoUrlLarge: logoUrlLarge ?? this.logoUrlLarge,
      address: address ?? this.address,
      playHQId: playHQId ?? this.playHQId,
      routingCode: routingCode ?? this.routingCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'logoUrl32': logoUrl32,
      'logoUrl48': logoUrl48,
      'logoUrlLarge': logoUrlLarge,
      'address': address?.toJson(),
      'playHQId': playHQId,
      'routingCode': routingCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team &&
        other.name == name &&
        other.logoUrl == logoUrl &&
        other.logoUrl32 == logoUrl32 &&
        other.logoUrl48 == logoUrl48 &&
        other.logoUrlLarge == logoUrlLarge &&
        other.address == address &&
        other.playHQId == playHQId &&
        other.routingCode == routingCode;
  }

  @override
  int get hashCode => Object.hash(
    name,
    logoUrl,
    logoUrl32,
    logoUrl48,
    logoUrlLarge,
    address,
    playHQId,
    routingCode,
  );

  @override
  String toString() =>
      'Team(name: $name, logoUrl: $logoUrl, logoUrl32: $logoUrl32, '
      'logoUrl48: $logoUrl48, logoUrlLarge: $logoUrlLarge, '
      'address: $address, playHQId: $playHQId, routingCode: $routingCode)';
}

/// base class for score-related data
@immutable
class ScoreData {
  const ScoreData({required this.goals, required this.behinds})
    : points = goals * 6 + behinds;
  final int goals;
  final int behinds;
  final int points;

  ScoreData copyWith({int? goals, int? behinds}) {
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

/// team with associated score information
class TeamScore {
  const TeamScore({
    required this.name,
    required this.score,
    this.isWinner = false,
  });
  final String name;
  final ScoreData score;
  final bool isWinner;

  TeamScore copyWith({String? name, ScoreData? score, bool? isWinner}) {
    return TeamScore(
      name: name ?? this.name,
      score: score ?? this.score,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}
