import 'package:beerpongapp/firestoreservice.dart';
import 'package:flutter/material.dart';
import '../models/game_statistics.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<GameStatistics> games = [];

  @override
  void initState() {
    super.initState();
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    games = await FirestoreService().retrieveGames();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Statistics'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return ListTile(
              title: Text('Game ${index + 1}'),
              subtitle: Text('Winning Team: ${game.winningTeam}'),
              onTap: () {
                _showGameDetails(game);
              },
            );
          },
        ),
      ),
    );
  }

  void _showGameDetails(GameStatistics game) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${game.date.toString()}'),
              Text('Winning Team: ${game.winningTeam}'),
              const Text('Team 1 Players:'),
              ...game.team1Players.map((player) => Text('${player.name}: Score - ${player.score}, Misses - ${player.misses}')),
              const Text('Team 2 Players:'),
              ...game.team2Players.map((player) => Text('${player.name}: Score - ${player.score}, Misses - ${player.misses}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
