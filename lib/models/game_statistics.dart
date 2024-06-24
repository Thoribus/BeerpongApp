import 'package:cloud_firestore/cloud_firestore.dart';
import 'player.dart'; // Import your Player class here

class GameStatistics {
  final DateTime date;
  final String winningTeam;
  final List<Player> team1Players;
  final List<Player> team2Players;
  final List<String> participants;

  GameStatistics({
    required this.date,
    required this.winningTeam,
    required this.team1Players,
    required this.team2Players,
    required this.participants,
  });

  factory GameStatistics.fromFirestore(Map<String, dynamic> data) {
    return GameStatistics(
      date: (data['timestamp'] as Timestamp).toDate(),
      winningTeam: data['winner'],
      team1Players: (data['team1'] as List<dynamic>).map((playerData) => Player.fromJson(playerData)).toList(),
      team2Players: (data['team2'] as List<dynamic>).map((playerData) => Player.fromJson(playerData)).toList(),
      participants: List<String>.from(data['participants']),
    );
  }
}
