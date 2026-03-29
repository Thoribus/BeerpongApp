import 'dart:async';

import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/theme.dart';
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
  GoRouter? _goRouter;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goRouter = GoRouter.of(context);
      _goRouter!.routerDelegate.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    _goRouter?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    // Use a short delay so any in-flight SharedPreferences writes (e.g. the
    // unawaited persist triggered by GameScreen.dispose) finish before we read.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _checkSavedGame();
    });
  }

  Future<void> _checkSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSavedGame = prefs.containsKey('currentGameState');
    if (!mounted) return;
    setState(() {
      _hasSavedGame = hasSavedGame;
    });
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
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildPlaySection(context, c),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Rulebook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildRulebookSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _onReturnFromNextScreen() => _checkSavedGame();

  void _navigate({required bool isTournament}) {
    void go() {
      context
          .push(
            '/game-mode',
            extra: GameModeArgs(
              title: isTournament ? 'Tournament' : 'Play Beerpong',
              subtitle:
                  isTournament ? 'Bracket-style play' : 'Quick, fun rounds',
              details: '',
              iconPath: isTournament
                  ? 'assets/racoon_winner.svg'
                  : 'assets/two_cats.svg',
              color: isTournament ? Colors.deepPurple : Colors.orange,
              isTournament: isTournament,
            ),
          )
          .then((_) => _onReturnFromNextScreen());
    }

    if (_hasSavedGame && !isTournament) {
      _showNewGameConfirmationDialog(context, go);
    } else {
      go();
    }
  }

  void _resumeGame() {
    context
        .push(
          '/game',
          extra: GameArgs(
            id: 'Resume Game',
            team1: Team(
              color: Colors.blue,
              players: [],
              cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
            ),
            team2: Team(
              color: Colors.red,
              players: [],
              cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
            ),
            selectedRules: const {},
            startingTeam: true,
            invitations: const [],
            tournamentId: '',
          ),
        )
        .then((_) => _onReturnFromNextScreen());
  }

  Widget _buildInvitationBadge(AppColors c) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<List<Invitation>>(
      stream: FirestoreService.instance.pendingInvitationsStream(user.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push(AppRoutes.invitations),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'You have 1 pending invitation'
                        : 'You have $count pending invitations',
                    style: TextStyle(
                      color: c.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: c.subtle),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaySection(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 210,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFE05000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Mascot — right side
                  Positioned(
                    right: -12,
                    bottom: -8,
                    child: Opacity(
                      opacity: 0.9,
                      child: SvgPicture.asset(
                        'assets/two_cats.svg',
                        width: 170,
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Text + buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Let's play!",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Beer Pong',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE05000),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () => _navigate(isTournament: false),
                              child: const Text(
                                'New Game',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            if (_hasSavedGame) ...[
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Colors.white60, width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _resumeGame,
                                child: const Text('Resume',
                                    style: TextStyle(fontSize: 15)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Pending invitations badge ──────────────────────────────────
          _buildInvitationBadge(c),

          // ── Tournament secondary button ────────────────────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: BorderSide(
                  color: Colors.deepPurple.withValues(alpha: 0.45), width: 1.5),
              backgroundColor:
                  Colors.deepPurple.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _navigate(isTournament: true),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: const Text(
              'Tournament',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
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

        final c = AppColors.of(context);
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.onBackground,
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
                          style: TextStyle(
                            fontSize: 15,
                            color: c.onBackground,
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
              color: c.surface2,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: c.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rule['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.subtle,
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
