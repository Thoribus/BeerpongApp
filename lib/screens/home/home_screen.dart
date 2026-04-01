import 'dart:async';

import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
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
      // Re-check after the first frame so that if the initState check was
      // interrupted by a GoRouter redirect rebuild (!mounted early return),
      // this run happens once the widget tree has settled.
      _checkSavedGame();
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
          title: Text(
            context.loc.homeNewGameDialogTitle,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            context.loc.homeNewGameDialogContent,
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                context.loc.btnCancel,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                context.loc.homeNewGameDialogConfirm,
                style: const TextStyle(
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
              _buildRulebookBanner(context, c),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _onReturnFromNextScreen() => _checkSavedGame();

  Future<void> _navigate({required bool isTournament}) async {
    void go() {
      context
          .push(
            '/game-mode',
            extra: GameModeArgs(
              title: isTournament ? context.loc.homeTournamentTitle : context.loc.homeGameModeTitle,
              subtitle: isTournament ? context.loc.homeTournamentSubtitle : context.loc.homeGameModeSubtitle,
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

    // Check SharedPreferences directly so the confirmation fires even when
    // _hasSavedGame hasn't been updated yet (e.g. within the 150 ms window
    // after returning from the game screen).
    if (!isTournament) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.containsKey('currentGameState')) {
        unawaited(_showNewGameConfirmationDialog(context, go));
        return;
      }
    }
    go();
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
                    context.loc.homePendingInvitations(count),
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
                        Text(
                          context.loc.homeLetsPlay,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.loc.homeBeerPong,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
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
                          onPressed: () => unawaited(_navigate(isTournament: false)),
                          child: Text(
                            context.loc.homeBtnNewGame,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Resume game card ───────────────────────────────────────────
          if (_hasSavedGame) ...[
            GestureDetector(
              onTap: _resumeGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.loc.homeResumeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            context.loc.homeResumeSubtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

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
            onPressed: () => unawaited(_navigate(isTournament: true)),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: Text(
              context.loc.labelTournament,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulebookBanner(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.rulebook),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.homeRulebookTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.loc.homeRulebookSubtitle,
                      style: TextStyle(fontSize: 12, color: c.subtle),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
