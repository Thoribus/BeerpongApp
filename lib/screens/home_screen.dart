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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/screens/lobby_screen.dart';
import 'package:beerpongapp/screens/game_mode_details_screen.dart';

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
                          const LobbyScreen()), // Navigate to the lobby
                );
              },
            ),
          ],
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
    final avatarAsset = player.user!.mapAvatarKeyToAsset();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildWelcomeTile(),
              const SizedBox(height: 20),
              _buildGameButton(context),
              _buildBracketExample(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Game Modes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGameModeTiles(context),
                  const SizedBox(height: 30),
                  const Text(
                    'Rulebook',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRulebookSection(),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReturnFromNextScreen() {
    _checkSavedGame();
  }
}

Widget _buildWelcomeTile() {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.waving_hand, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              'Welcome Back, ${userProvider.user?.username ?? "User"}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildGameModeTiles(BuildContext context) {
  final gameModes = [
    {
      'title': 'Classic Mode',
      'subtitle': 'Play the original game',
      'color': Colors.blue,
      'details': 'Quick, fun rounds',
      'icon': 'racoon_winner.svg',
    },
    {
      'title': 'Tournament Mode',
      'subtitle': 'Compete with others',
      'color': Colors.deepPurple,
      'details': 'Coming Soon!',
      'icon': 'racoon_winner.svg',
    },
    {
      'title': 'Practice Mode',
      'subtitle': 'Sharpen your skills',
      'color': Colors.orange,
      'details': 'No pressure',
      'icon': 'racoon_winner.svg',
    },
  ];

  return SizedBox(
    height: 300,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: gameModes.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final mode = gameModes[index];
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: mode['color'] as Color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (mode['color'] as Color).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['subtitle'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: SvgPicture.asset(
                        'assets/${mode['icon']}',
                        width: 80,
                        height: 80,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      mode['details'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 48), // leave space for the button
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    backgroundColor: Colors.black.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameModeDetailsScreen(
                          title: mode['title'] as String,
                          subtitle: mode['subtitle'] as String,
                          details: mode['details'] as String,
                          iconPath: 'assets/${mode['icon']}',
                          color: mode['color'] as Color,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Play Now',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildRulebookSection() {
  final rules = [
    {
      'title': 'Overtime Rules',
      'description': 'Learn what happens in a tie situation.',
      'longDescription':
          'In the event of a tie, the game proceeds to an overtime round. Each team gets an additional turn to try and outscore the opponent. If still tied, the game continues until one team leads after a complete round.',
      'iconName': 'frog_island',
      'rating': 4,
    },
    {
      'title': 'Re-Rack Mechanics',
      'description': 'Understand how re-racks work mid-game.',
      'longDescription':
          'Re-racks are allowed at designated points during the game. Teams may request a rearrangement of cups, with standard formations such as "diamond", "line", or "triangle". Misuse may result in forfeiture of turn.',
      'iconName': 'frog_island',
      'rating': 3,
    },
    {
      'title': 'Redemption Rules',
      'description': 'See how redemption throws are handled.',
      'longDescription':
          'When one team clears the opponent’s cups, the losing team is granted redemption throws. Each player gets one chance to bring the game into overtime. Missing any results in an immediate loss.',
      'iconName': 'frog_island',
      'rating': 5,
    },
  ];

  return SizedBox(
    height: 160,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        final int rating = (rule['rating'] as int?) ?? 0;

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/${rule['iconName']}.svg',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          rule['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 24,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          rule['longDescription'] as String,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: 220,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/${rule['iconName']}.svg',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < rating ? Icons.star : Icons.star_border,
                          size: 20,
                          color: Colors.amber,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rule['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rule['description'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
