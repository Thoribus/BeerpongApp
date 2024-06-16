import 'package:beerpongapp/screens/friendlist.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:beerpongapp/screens/account_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize:
            Size.fromHeight(kToolbarHeight + 20), // Adjust height as needed
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SelectionScreen()),
                            );
                          },
                          child: const Text('Neues Spiel'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    height: 20), // Add some spacing between the elements
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Statistik screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                  icon: Icons.bar_chart,
                  label: 'Statistik',
                ),
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendsListScreen(),
                      ),
                    );
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
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Einstellungen screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountScreen(),
                      ),
                    );
                  },
                  icon: Icons.account_circle_rounded,
                  label: 'Account',
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
          offset: const Offset(0, 3),
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
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.withOpacity(0.75), // Amber color with low opacity
      child: AppBar(
        title: const Text(
          'BeerPong!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.withOpacity(0.75),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            print('Menu Icon Pressed');
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.sports_bar_rounded),
            onPressed: () {
              print('Beer Icon Pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              print('Settings Icon Pressed');
            },
          ),
        ],
      ),
    );
  }
}
