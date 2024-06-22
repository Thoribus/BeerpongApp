import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStatistics {
  final String name;
  final double score;
  final int misses;

  PlayerStatistics({required this.name, required this.score, required this.misses});

  factory PlayerStatistics.fromFirestore(Map<String, dynamic> data) {
    return PlayerStatistics(
      name: data['name'],
      score: data['score'],
      misses: data['misses'],
    );
  }
}

class GameStatistics {
  final DateTime date;
  final String winningTeam;
  final List<PlayerStatistics> team1Players;
  final List<PlayerStatistics> team2Players;
  final List<String> participants;

  GameStatistics({
    required this.date,
    required this.winningTeam,
    required this.team1Players,
    required this.team2Players,
    required this.participants,
  });

  factory GameStatistics.fromFirestore(Map<String, dynamic> data) {
    print("Hello");
    return GameStatistics(
      date: (data['timestamp'] as Timestamp).toDate(),
      winningTeam: data['winner'],
      team1Players: (data['team1'] as List<dynamic>).map((playerData) => PlayerStatistics.fromFirestore(playerData)).toList(),
      team2Players: (data['team2'] as List<dynamic>).map((playerData) => PlayerStatistics.fromFirestore(playerData)).toList(),
      participants: List<String>.from(data['participants']),
    );
  }
}
