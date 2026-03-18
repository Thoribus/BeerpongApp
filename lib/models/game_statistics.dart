import 'package:cloud_firestore/cloud_firestore.dart';
import 'player.dart'; // Import your Player class here

class GameStatistics {
  final String id;
  final DateTime date;
  final String winningTeam;
  final List<Player> team1Players;
  final List<Player> team2Players;
  final List<String> participants;
  final int roundCount;
  final int? cupsRemainingWinner;
  final int? durationSeconds;
  final String gameMode;
  final List<String> specialRules;

  GameStatistics({
    required this.id,
    required this.date,
    required this.winningTeam,
    required this.team1Players,
    required this.team2Players,
    required this.participants,
    this.roundCount = 0,
    this.cupsRemainingWinner,
    this.durationSeconds,
    this.gameMode = 'Single Game',
    this.specialRules = const [],
  });

  factory GameStatistics.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final endedAt = (data['endedAt'] as Timestamp?)?.toDate();
    final durationSeconds = (timestamp != null && endedAt != null)
        ? endedAt.difference(timestamp).inSeconds
        : null;

    return GameStatistics(
      id: id,
      date: timestamp ?? DateTime.now(),
      winningTeam: data['winner'] as String? ?? '',
      team1Players: (data['team1']['players'] as List<dynamic>)
          .map((playerData) => Player.fromJson(playerData))
          .toList(),
      team2Players: (data['team2']['players'] as List<dynamic>)
          .map((playerData) => Player.fromJson(playerData))
          .toList(),
      participants: List<String>.from(data['participants'] ?? []),
      roundCount: data['roundCount'] as int? ?? 0,
      cupsRemainingWinner: data['cupsRemainingWinner'] as int?,
      durationSeconds: durationSeconds,
      gameMode: data['gameMode'] as String? ?? 'Single Game',
      specialRules: List<String>.from(data['specialRules'] ?? []),
    );
  }
}

/// Holds the stats for a single user (Player) in a single game, along with the game timestamp.
class UserStatsInGame {
  final DateTime date; // The game’s timestamp or date
  final Player player; // The user's player stats in that game

  UserStatsInGame({required this.date, required this.player});
}
