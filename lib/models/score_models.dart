import 'playhq_models.dart';

/// Team data with optional logos in multiple sizes and address information
class Team {
  final String name;
  final String? logoUrl;
  final String? logoUrl32;
  final String? logoUrl48;
  final String? logoUrlLarge;
  final Address? address;
  final String? playHQId; // Store PlayHQ organisation ID for future lookups
  final String? routingCode; // Store PlayHQ routing code for address fetching

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

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
      logoUrl32: json['logoUrl32'],
      logoUrl48: json['logoUrl48'],
      logoUrlLarge: json['logoUrlLarge'],
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      playHQId: json['playHQId'],
      routingCode: json['routingCode'],
    );
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
      'Team(name: $name, logoUrl: $logoUrl, logoUrl32: $logoUrl32, logoUrl48: $logoUrl48, logoUrlLarge: $logoUrlLarge, address: $address, playHQId: $playHQId, routingCode: $routingCode)';
}

/// Base class for score-related data
class ScoreData {
  final int goals;
  final int behinds;
  final int points;

  const ScoreData({required this.goals, required this.behinds})
    : points = goals * 6 + behinds;

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

  TeamScore copyWith({String? name, ScoreData? score, bool? isWinner}) {
    return TeamScore(
      name: name ?? this.name,
      score: score ?? this.score,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}
