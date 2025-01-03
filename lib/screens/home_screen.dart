import 'package:beerpongapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';

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
    _initializeSavedGameState();
  }

  Future<void> _initializeSavedGameState() async {
    final hasSavedGame = await _checkSavedGame();
    setState(() {
      _hasSavedGame = hasSavedGame;
    });
  }

  Future<bool> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('team1Cups') && prefs.containsKey('team2Cups');
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    const keysToRemove = [
      'team1Cups',
      'team2Cups',
      'team1Players',
      'team2Players',
      'isTeamOneTurn',
      'islandShotActive',
      'team1IsRearranged',
      'team2IsRearranged',
    ];
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    setState(() {
      _hasSavedGame = false;
    });
  }

  Future<void> _showNewGameConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.primaryColor,
          title: const Text(
            'New Game',
            style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Starting a new game will delete the current game. Do you want to continue?',
            style: TextStyle(color: AppConstants.secondaryColor),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Start New Game',
                style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _clearSavedGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectionScreen(onReturn: _refreshSavedGameState),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _refreshSavedGameState() => _initializeSavedGameState();

  Widget _buildWelcomeText() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            'Welcome Back, ${userProvider.user?.username ?? "User"}',
            style: const TextStyle(
              color: AppConstants.secondaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 26, 26, 1),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(color: AppConstants.secondaryColor, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resume Game',
                  style: TextStyle(color: AppConstants.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  onPressed: _hasSavedGame
                      ? () => Navigator.push(
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
                          )
                      : null,
                  child: const Text(
                    'Resume',
                    style: TextStyle(color: AppConstants.secondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Start New Game',
                  style: TextStyle(color: AppConstants.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  onPressed: () {
                    if (_hasSavedGame) {
                      _showNewGameConfirmationDialog();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectionScreen(onReturn: _refreshSavedGameState),
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.add,
                    color: AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.secondaryColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/amber_fullscreen_home.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeText(),
                const Spacer(),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildGameButtons(),
                      const SizedBox(height: 60),
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
