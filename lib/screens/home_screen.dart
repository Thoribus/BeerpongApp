import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/statistics_screen.dart';
import '../models/player.dart';
import '../widgets/new_game_dialog.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(kToolbarHeight + 20), // Adjust height as needed
        child: CustomAppBar(),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 3.0),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.asset(
                          'assets/beerpong.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () async {
                            // Show dialog for team 1 and cast the result to List<String>
                            final team1Result = await showDialog<List<String>>(
                              context: context,
                              builder: (context) =>
                                  const NewGameDialog(team: 1),
                            );

                if (team1Result != null) {
                  final players1 =
                      team1Result.map((name) => Player(name: name)).toList();

                              // Show dialog for team 2 and cast the result to List<String>
                              final team2Result =
                                  await showDialog<List<String>>(
                                context: context,
                                builder: (context) =>
                                    const NewGameDialog(team: 2),
                              );
                  if (team2Result != null) {
                    final players2 =
                        team2Result.map((name) => Player(name: name)).toList();

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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Add some spacing between the elements
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Statistik screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(
                        ),
                      ),
                    );
                  },
                  icon: Icons.bar_chart,
                  label: 'Statistik',
                ),
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Freundesliste screen
                  },
                  icon: Icons.people_alt_rounded,
                  label: 'Freundesliste',
                ),
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Einstellungen screen
                  },
                  icon: Icons.settings,
                  label: 'Einstellungen',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildElevatedButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.75,
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.amber, width: 3.0),
      borderRadius: BorderRadius.circular(15.0),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.7),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class CustomAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.withOpacity(0.5), // Amber color with low opacity
      child: AppBar(
        title: const Text('Beerpong App'),
        backgroundColor:
            Colors.transparent, // Make app bar background transparent
        elevation: 3, // Remove elevation
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            print('Menu Icon Pressed');
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sports_bar_rounded),
            onPressed: () {
              print('Beer Icon Pressed');
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              print('Settings Icon Pressed');
            },
          ),
        ],
      ),
    );
  }
}
