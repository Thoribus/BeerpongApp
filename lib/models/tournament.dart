// tournament.dart
import 'team.dart';

enum TournamentType { roundRobin }

class Tournament {
  final String id;
  final String name;
  final TournamentType type;
  final List<Team> teams;
  final List<TournamentMatch> matches;
  final bool started;
  final bool finished;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.name,
    this.type = TournamentType.roundRobin,
    required this.teams,
    required this.matches,
    this.started = false,
    this.finished = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Tournament copyWith({
    String? id,
    String? name,
    TournamentType? type,
    List<Team>? teams,
    List<TournamentMatch>? matches,
    bool? started,
    bool? finished,
    DateTime? createdAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
      started: started ?? this.started,
      finished: finished ?? this.finished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      type: TournamentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TournamentType.roundRobin,
      ),
      teams: (json['teams'] as List<dynamic>)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList(),
      matches: (json['matches'] as List<dynamic>)
          .map((e) => TournamentMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      started: json['started'] ?? false,
      finished: json['finished'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'teams': teams.map((t) => t.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'started': started,
      'finished': finished,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TournamentMatch {
  final String id;
  final Team team1;
  final Team team2;
  final int round;
  final Team? winner;
  final bool played;

  TournamentMatch({
    required this.id,
    required this.team1,
    required this.team2,
    this.round = 0,
    this.winner,
    this.played = false,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      team1: Team.fromJson(json['team1'] as Map<String, dynamic>),
      team2: Team.fromJson(json['team2'] as Map<String, dynamic>),
      round: json['round'] ?? 0,
      winner: json['winner'] != null
          ? Team.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      played: json['played'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'round': round,
      'winner': winner?.toJson(),
      'played': played,
    };
  }
}

class TeamStanding {
  final Team team;
  int wins;
  int losses;

  TeamStanding({
    required this.team,
    this.wins = 0,
    this.losses = 0,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      team: Team.fromJson(json['team'] as Map<String, dynamic>),
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team.toJson(),
      'wins': wins,
      'losses': losses,
    };
  }
}

// Generate all unique matchups for round robin
List<TournamentMatch> generateRoundRobinMatches(List<Team> teams) {
  final matches = <TournamentMatch>[];
  int matchId = 0;
  for (int i = 0; i < teams.length; i++) {
    for (int j = i + 1; j < teams.length; j++) {
      matches.add(TournamentMatch(
        id: 'match_${matchId++}',
        team1: teams[i],
        team2: teams[j],
        round: 0, // (optional: assign a round/group if you want!)
      ));
    }
  }
  return matches;
}

// Calculate standings based on played matches
List<TeamStanding> computeStandings(
    List<Team> teams, List<TournamentMatch> matches) {
  final standings = {
    for (final team in teams)
      team.color.value.toString() +
              team.players.map((p) => p.name).join('-'): // Unique-ish key
          TeamStanding(team: team, wins: 0, losses: 0)
  };

  for (final match in matches) {
    if (!match.played || match.winner == null) continue;
    final keyWinner = match.winner!.color.value.toString() +
        match.winner!.players.map((p) => p.name).join('-');
    final loserTeam = (match.team1 == match.winner) ? match.team2 : match.team1;
    final keyLoser =
        loserTeam.color.value.toString() + loserTeam.players.map((p) => p.name).join('-');

    standings[keyWinner]!.wins++;
    standings[keyLoser]!.losses++;
  }
  return standings.values.toList();
}
