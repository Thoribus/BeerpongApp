import 'package:flutter/material.dart';
import '../models/player.dart';
import '../widgets/new_game_dialog.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                // Show dialog for team 1 and cast the result to List<String>
                final team1Result = await showDialog<List<String>>(
                  context: context,
                  builder: (context) => const NewGameDialog(team: 1),
                );

                if (team1Result != null) {
                  final players1 =
                      team1Result.map((name) => Player(name)).toList();

                  // Show dialog for team 2 and cast the result to List<String>
                  final team2Result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => const NewGameDialog(team: 2),
                  );

                  if (team2Result != null) {
                    final players2 =
                        team2Result.map((name) => Player(name)).toList();

                    // Navigate to the game screen with both teams' players
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                          title: 'Beer Pong',
                          players1: players1,
                          players2: players2,
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Neues Spiel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Statistik screen
              },
              child: const Text('Statistik'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Freundesliste screen
              },
              child: const Text('Freundesliste'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Einstellungen screen
              },
              child: const Text('Einstellungen'),
            ),
          ],
        ),
      ),
    );
  }
}
