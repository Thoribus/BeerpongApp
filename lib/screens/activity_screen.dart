import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
import '../models/game_statistics.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  ActivityScreenState createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> {
  List<UserStatsInGame> games = [];
  bool isLoading = true;
  bool hasError = false;
  late User? user;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    user = userProvider.user;
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    try {
      games = await FirestoreService().retrieveUserStatsWithDate(user!);
    } catch (e) {
      hasError = true;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  static void calculateActivity(UserStatsInGame game) {
    final player = game.player;
    if (player.user == null) return;
    final user = player.user!;
    final newUser = FirestoreService.mapPlayerToUser(player);

    double winRateDelta = newUser.winRate - user.winRate;
    double hitRateDelta = newUser.hitRate - user.hitRate;
    num scoreIncrease = player.score;

    print(scoreIncrease);
    print(hitRateDelta);
    print(winRateDelta);
    List<Map<String, String>> upgrades =
        AchievementsScreen.getUpgradedAchivements(player);
    print(upgrades);
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
      backgroundColor: Colors.white,
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

  Widget _buildGameCard(UserStatsInGame game, int index) {
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
                calculateActivity(game);
              },
              child: const Text('Track progress'),
            ),
          ],
        ),
      ),
    );
  }
}
