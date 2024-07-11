import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/game_screen.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import the SVG package

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSavedGame =
        prefs.containsKey('team1Cups') && prefs.containsKey('team2Cups');
    setState(() {
      _hasSavedGame = hasSavedGame;
    });
  }

  Future<void> _clearSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> keys = [
      'team1Cups',
      'team2Cups',
      'team1Players',
      'team2Players',
      'isTeamOneTurn',
      'islandShotActive',
      'team1IsRearranged',
      'team2IsRearranged'
    ];
    for (String key in keys) {
      await prefs.remove(key);
    }
    setState(() {
      _hasSavedGame = false;
    });
  }

  Future<void> _showNewGameConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.amber, // Set dialog background color to amber
          title: const Text(
            'New Game',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold, // Make the title text bold
            ),
          ),
          content: const Text(
            'Starting a new game will delete the current game. Do you want to continue?',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold, // Make the button text bold
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Start New Game',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold, // Make the button text bold
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _clearSavedGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SelectionScreen(onReturn: _onReturnFromNextScreen)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Welcome Back, User!',
        style: TextStyle(
          color: Colors.black, // Set the text color to amber
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGameButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color:
            Color.fromRGBO(27, 26, 26, 1), // Set the background color to black
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Game',
                  style: TextStyle(
                    color: Colors.amber, // Set the text color to amber
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasSavedGame)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green, // Set the button color to green
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(
                            title: 'Resume Game',
                            players1: [],
                            players2: [],
                            selectedRules: {},
                            startingTeam: true,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                          color: Colors.black), // Set the text color to black
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.amber, // Set the button color to amber
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  onPressed: () {
                    if (_hasSavedGame) {
                      _showNewGameConfirmationDialog(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectionScreen(
                                onReturn: _onReturnFromNextScreen)),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.add,
                    color: Colors.black, // Set the icon color to black
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onReturnFromNextScreen() {
    _checkSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background SVG Image
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/amber_fullscreen_home.svg', // Updated to use asset directory
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildWelcomeText(),
                const Spacer(),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _buildGameButton(context),
                      const SizedBox(
                          height: 60), // Add spacing above the button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
