import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSavedGame = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();

    // Initialize animation controller and animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween(begin: 2.0, end: 15.0).animate(_animationController);

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          title: const Text('New Game'),
          content: const Text(
              'Starting a new game will delete the current game. Do you want to continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Start New Game'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _clearSavedGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectionScreen(onReturn: _onReturnFromNextScreen,)),
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      alignment: Alignment.center,
      child: const Text(
        'Welcome, X!', // Display username retrieved from user.dart
        style: TextStyle(
          color: Colors.white,
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
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.amber, width: 3.0),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.8),
            blurRadius: _animation.value,
            spreadRadius: _animation.value,
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Image.asset(
              'assets/animals_beerpong.jpg',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'New Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (_hasSavedGame) {
                      _showNewGameConfirmationDialog(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectionScreen(onReturn: _onReturnFromNextScreen,)),
                      );
                    }
                  },
                  child: const Icon(Icons.add),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildWelcomeText(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildGameButton(context),
                    const SizedBox(height: 40),
                    if (_hasSavedGame)
                      ElevatedButton.icon(
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
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
