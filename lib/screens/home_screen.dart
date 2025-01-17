import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/screens/spectate_lobby_screen.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/screens/lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;
  bool _hasInvitations = false;
  final List<Invitation> _invitations = [];
  double _progress = 0.0;

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
        setState(() {
          _invitations.add(invite);
        });
      }
      setState(() {
        _hasInvitations = true;
      });
    } else {
      setState(() {
        _hasInvitations = false;
      });
    }
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
                // Also Delete the saved game in the database
                await GamePersistence.clearGameState(true);
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
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          alignment: Alignment.centerLeft,
          child: Text(
            'Welcome Back, ${userProvider.user?.username ?? "User"}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
                    backgroundColor:
                        _hasInvitations ? Colors.grey : Colors.amber,
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
                            builder: (context) => const LobbyScreen()),
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

  Widget _buildSvgBracket() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.amber,
                    width: 4.0,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: SvgPicture.asset(
                    'assets/home_animals.svg', // Adjust the path as needed
                    height: 245.0,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBracketExample() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BEERPONG BATTLE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReadOnlyLobbyScreen(
                              gameId: _invitations[0].gameId,
                            )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Spectate",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
            ),
            child: _invitations.isEmpty
                ? const Center(
                    child: Text(
                      "No invitations available",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: _invitations.length,
                    itemBuilder: (context, index) {
                      return _buildInvitationCard(_invitations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Invitation invite) {
    final firestoreService = FirestoreService();

    return StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getGameDocStream(invite.gameId),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Game not found.',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          // Extract game data
          final gameData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          Team team1 = Team.fromJson(gameData['team1']);
          Team team2 = Team.fromJson(gameData['team2']);

          return Card(
            color: Colors.grey[900],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Invitation",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              "${team1.players.length} VS ${team2.players.length}",
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star_border_outlined, color: Colors.amber),
                          Icon(Icons.star_border_outlined, color: Colors.green),
                          Icon(Icons.star_border_outlined, color: Colors.blue),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Loop over the players in the game and build their avatars
                      for (Player player in team1.players)
                        _buildPlayerAvatar(player, Colors.amber),
                      const Text(" VS ", style: TextStyle(color: Colors.white)),
                      for (Player player in team2.players)
                        _buildPlayerAvatar(player, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50, // Same height as the button
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            stops: [_progress, _progress + 0.01],
                            colors: const [
                              Colors
                                  .grey, // Gradually appears as progress increases
                              Colors.amber,
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .transparent, // Transparent to show the gradient
                          shadowColor:
                              Colors.transparent, // Removes button shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () async {
                          await FirestoreService()
                              .updateInvitationStatus(invite.id, "accepted");
                        },
                        child: const Text(
                          "You got 30s to join. Hurry up!",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildPlayerAvatar(Player player, Color color) {
    if (player.user == null) return _buildEmptyAvatar();
    final avatarAsset = _mapAvatarKeyToAsset(player.user!.avatarKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white24,
          child: avatarAsset.isNotEmpty
              ? ClipOval(
                  child: SvgPicture.asset(
                    avatarAsset,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    placeholderBuilder: (BuildContext context) => Container(
                      color: Colors.grey,
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.person, color: Colors.white70),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _progress,
      backgroundColor: Colors.grey[800],
      color: Colors.amberAccent,
      minHeight: 6,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWelcomeText(context),
              _buildGameButton(context),
              _buildSvgBracket(),
              _buildBracketExample(),
            ],
          ),
        ),
      ),
    );
  }

  void _onReturnFromNextScreen() {
    _checkSavedGame();
  }

  /// Maps a given avatarKey to the actual local asset path.
  /// For example: 'bunny' -> 'assets/avatars/bunny.png'
  String _mapAvatarKeyToAsset(String avatarKey) {
    if (avatarKey.isEmpty) return '';
    // Adjust as needed for your file naming structure
    return 'assets/avatars/$avatarKey.svg';
  }
}
