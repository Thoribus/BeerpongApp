import 'package:flutter/material.dart'; // Importing necessary Flutter package
import '../models/player.dart'; // Importing Player model
import '../widgets/new_game_dialog.dart'; // Importing NewGameDialog widget
import 'game_screen.dart'; // Importing game screen

// HomeScreen is a stateless widget that represents the home screen of the application.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'), // AppBar with title 'Home Screen'
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Button to start a new game
            ElevatedButton(
              onPressed: () {
                // Show dialog to enter player names for team 1
                showDialog(
                  context: context,
                  builder: (context) => const NewGameDialog(team: 1)).then((result) {
                  if (result != null) {
                    // Start the game with the entered player names for team 1
                    String player1Name = result[0];
                    String player2Name = result[1];
                    // Show dialog to enter player names for team 2
                    showDialog(
                        context: context,
                        builder: (context) => const NewGameDialog(team: 2)).then((result) {
                      if (result != null) {
                        // Start the game with the entered player names for team 2
                        String player3Name = result[0];
                        String player4Name = result[1];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              title: 'Beer Pong',
                              players: [
                                Player(player1Name),
                                Player(player2Name),
                                Player(player3Name),
                                Player(player4Name),
                              ],
                            ),
                          ),
                        );
                      }
                    });
                  }
                });
              },
              child: const Text('Neues Spiel'), // Button label 'Neues Spiel'
            ),
            // Button to navigate to Statistik screen
            ElevatedButton(
              onPressed: () {
                // Navigate to Statistik screen
              },
              child: const Text('Statistik'), // Button label 'Statistik'
            ),
            // Button to navigate to Freundesliste screen
            ElevatedButton(
              onPressed: () {
                // Navigate to Freundesliste screen
              },
              child: const Text('Freundesliste'), // Button label 'Freundesliste'
            ),
            // Button to navigate to Einstellungen screen
            ElevatedButton(
              onPressed: () {
                // Navigate to Einstellungen screen
              },
              child: const Text('Einstellungen'), // Button label 'Einstellungen'
            ),
          ],
        ),
      ),
    );
  }
}
