import 'dart:async';

import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _hasSavedGame = false;
  bool _hasInvitations = false;
  final List<Invitation> _invitations = [];

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
        await FirestoreService.instance.getAllInvitations(currentUser.id);

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

  Future<void> _showNewGameConfirmationDialog(
      BuildContext context, VoidCallback onConfirm) async {
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
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40), // Give space for SVG overflow
              _buildSectionTitle('Game Modes'),
              const SizedBox(height: 20),

              // Wrap in Stack to allow overflow
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildGameModeTiles(context),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionTitle('Rulebook'),
              const SizedBox(height: 10),
              _buildRulebookSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _onReturnFromNextScreen() {
    _checkSavedGame();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGameModeTiles(BuildContext context) {
    final gameModes = [
      {
        'title': 'Play Beerpong',
        'tag': 'Classic Mode',
        'subtitle': 'Quick, fun rounds',
        'details': 'Resume or start a new game',
        'color': Colors.orange,
        'icon': 'two_cats.svg',
      },
      {
        'title': 'Tournament',
        'tag': 'Competitive',
        'subtitle': 'Coming Soon!',
        'details': 'Coming Soon!',
        'color': Colors.deepPurple,
        'icon': 'racoon_winner.svg',
      },
      {
        'title': 'Practice Mode',
        'tag': 'Casual',
        'subtitle': 'Sharpen your skills',
        'details': 'No pressure',
        'color': Colors.blue,
        'icon': 'otter_canvas.svg',
      },
    ];

    PageController pageController = PageController(viewportFraction: 0.9);
    ValueNotifier<int> pageIndexNotifier = ValueNotifier<int>(0);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: pageController,
            itemCount: gameModes.length,
            onPageChanged: (index) => pageIndexNotifier.value = index,
            itemBuilder: (context, index) {
              final mode = gameModes[index];
              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (pageController.position.haveDimensions) {
                    scale = pageController.page! - index;
                    scale = (1 - (scale.abs() * 0.1)).clamp(0.9, 1.0);
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: mode['color'] as Color,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (mode['color'] as Color).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    mode['tag'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  mode['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mode['subtitle'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                const Divider(color: Colors.white24),
                                Text(
                                  mode['details'] as String,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),

                          // SVG Icon
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/${mode['icon']}',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Resume Game Button
                          if (_hasSavedGame)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  context.push('/game', extra: GameArgs(
                                    id: 'Resume Game',
                                    team1: Team(
                                      color: Colors.blue,
                                      players: [],
                                      cups: List.generate(
                                          10,
                                          (index) => Cup(
                                              index: index,
                                              color: Colors.blue)),
                                    ),
                                    team2: Team(
                                      color: Colors.red,
                                      players: [],
                                      cups: List.generate(
                                          10,
                                          (index) => Cup(
                                              index: index,
                                              color: Colors.red)),
                                    ),
                                    selectedRules: const {},
                                    startingTeam: true,
                                    invitations: const [],
                                    tournamentId: '',
                                  ));
                                },
                                child: const Text(
                                  'Resume',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),

                          // Stylized Play Button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                if (_hasInvitations) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('You are currently in a game.'),
                                    ),
                                  );
                                  return;
                                }
                                if (_hasSavedGame) {
                                  _showNewGameConfirmationDialog(context, () {
                                    context.push('/game-mode', extra: GameModeArgs(
                                      title: mode['title']! as String,
                                      subtitle: mode['subtitle']! as String,
                                      details: mode['details']! as String,
                                      iconPath: 'assets/${mode['icon'] as String}',
                                      color: mode['color'] as Color,
                                    ));
                                  });
                                } else {
                                  if (mode['title'] == 'Tournament') {
                                    context.push('/tournament-lobby', extra: GameModeArgs(
                                      title: mode['title'] as String,
                                      subtitle: mode['subtitle'] as String,
                                      details: mode['details'] as String,
                                      iconPath: 'assets/${mode['icon']}',
                                      color: mode['color'] as Color,
                                    ));
                                    return;
                                  }
                                  context.push('/game-mode', extra: GameModeArgs(
                                    title: mode['title'] as String,
                                    subtitle: mode['subtitle'] as String,
                                    details: mode['details'] as String,
                                    iconPath: 'assets/${mode['icon']}',
                                    color: mode['color'] as Color,
                                  )).then((_) {
                                    _onReturnFromNextScreen();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.white70],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: mode['color'] as Color,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Page indicators
        ValueListenableBuilder<int>(
          valueListenable: pageIndexNotifier,
          builder: (context, currentIndex, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gameModes.length, (index) {
                final isActive = index == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.orange
                        : Colors.orange.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
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
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
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
