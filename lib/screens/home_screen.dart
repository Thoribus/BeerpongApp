import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;
  bool _hasInvitations = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    _checkPendingInvitations();
  }

  Future<void> _checkSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSavedGame = prefs.containsKey('currentGameState');
    setState(() {
      _hasSavedGame = hasSavedGame;
    });
  }

  Future<void> _checkPendingInvitations() async {
    // If you already have a saved game, don't check for invitations.
    // Finish the game first.
    if (_hasSavedGame) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) return;

    List<Invitation> invites =
        await FirestoreService().getAllInvitations(currentUser.id);

    if (invites.isNotEmpty) {
      for (Invitation invite in invites) {
        if (invite.status == "pending") {
          _showInvitationDialog(invites.first);
          return;
        }
      }
      setState(() {
        _hasInvitations = true;
      });
    }
    else {
      setState(() {
        _hasInvitations = false;
      });
    }
  }

  /// Shows a popup with Accept/Decline for the given invitation.
  void _showInvitationDialog(Invitation invite) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Game Invitation"),
          content: Text(
            "You've been invited by user ${invite.fromUserId} to join "
            "Team ${invite.teamNumber}. "
            "Do you accept?",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Decline
                await FirestoreService()
                    .updateInvitationStatus(invite.id, "declined");
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You declined the invitation.')),
                );
              },
              child: const Text("Decline"),
            ),
            TextButton(
              onPressed: () async {
                // Accept
                await FirestoreService()
                    .updateInvitationStatus(invite.id, "accepted");
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You accepted the invitation!')),
                );

                // (Optional) Add user to the actual game doc.
                // e.g., FirestoreService().addPlayerToGame(invite.gameId, currentUser.id, invite.teamNumber);
              },
              child: const Text("Accept"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNewGameConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: const Text(
            'New Game',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await GamePersistence.clearGameState();
                setState(() {
                  _hasSavedGame = false;
                });
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

  Widget _buildWelcomeText(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            'Welcome Back, ${userProvider.user?.username ?? "User"}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 26, 26, 1),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
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
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasSavedGame)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                            id: 'Resume Game',
                            players1: [],
                            players2: [],
                            selectedRules: {},
                            startingTeam: true,
                            invitations: [],
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Resume',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasInvitations ? Colors.grey : Colors.amber,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  onPressed: () {
                    if (_hasInvitations) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You are currently in a game.',
                          ),
                        ),
                      );
                      //return;
                    }
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
                    color: Colors.black,
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
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/amber_fullscreen_home.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildWelcomeText(context),
                const Spacer(),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _buildGameButton(context),
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
