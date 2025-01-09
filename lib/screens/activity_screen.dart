import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
import '../models/game_statistics.dart';
import '../models/player.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  ActivityScreenState createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> {
  List<GameStatistics> games = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    try {
      games = await FirestoreService().retrieveGames();
    } catch (e) {
      hasError = true;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Track the progress towards achievements for each game
  void _progressEachGame(GameStatistics game) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      return;
    }
    if (game.participants.contains(currentUser.id)) {
      // User participated in this game
      final userStats = game.team1Players
          .where((player) => player.user?.id == currentUser.id)
          .map((player) => UserStatsInGame(date: game.date, player: player))
          .toList();
      userStats.addAll(game.team2Players
          .where((player) => player.user?.id == currentUser.id)
          .map((player) => UserStatsInGame(date: game.date, player: player))
          .toList());

      // Now you can track the user's progress in each game
      for (final stats in userStats) {
        print("Old Score: ${currentUser.totalScore - stats.player.score} New Score: ${currentUser.totalScore}");
        print("Old Misses: ${currentUser.totalMisses - stats.player.misses} New Misses: ${currentUser.totalMisses}");
        print("Old Airballs: ${currentUser.totalAirballs - stats.player.airballs} New Airballs: ${currentUser.totalAirballs}");
        // Track the user's progress in this game
        // ...
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }
    if (hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Failed to load games',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _buildGameCard(game, index);
          },
        ),
      ),
    );
  }

  Widget _buildGameCard(GameStatistics game, int index) {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game ${games.length - index}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _progressEachGame(game);
              },
              child: const Text('Track progress'),
            ),
          ],
        ),
      ),
    );
  }
}