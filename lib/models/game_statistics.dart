import 'player.dart';

class GameStatistics {
  final DateTime date;
  final List<Player> team1Players;
  final List<Player> team2Players;
  final String winningTeam;


  GameStatistics({
    required this.date,
    required this.team1Players,
    required this.team2Players,
    required this.winningTeam,
  });
}