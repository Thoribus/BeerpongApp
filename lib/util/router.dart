import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/auth/login_screen.dart';
import 'package:beerpongapp/screens/friends/compare_stats_screen.dart';
import 'package:beerpongapp/screens/friends/friendlist.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/screens/home/game_mode_details_screen.dart';
import 'package:beerpongapp/screens/home/home_screen.dart';
import 'package:beerpongapp/screens/invitations/invitation_inbox_screen.dart';
import 'package:beerpongapp/screens/invitations/waiting_for_game_screen.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/screens/profile/account_screen.dart';
import 'package:beerpongapp/screens/shop/shop_screen.dart';
import 'package:beerpongapp/screens/games/statistics_screen.dart';
import 'package:beerpongapp/screens/tournament/tournament_page_view.dart';
import 'package:beerpongapp/screens/base/base_screen.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  /// Accessible from anywhere (e.g. NotificationService) after [createRouter]
  /// has been called once during app startup.
  static late GoRouter router;

  static GoRouter createRouter(UserProvider userProvider) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: userProvider,
      redirect: (context, state) {
        // Wait for session restore before making auth decisions.
        if (userProvider.isLoading) return null;

        final loggedIn = userProvider.user != null;
        final onLogin = state.matchedLocation == '/login';

        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => BaseScreen(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/shop', builder: (_, __) => const ShopScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/friends',
                  builder: (_, __) => const FriendsListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/home', builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/games',
                  builder: (_, __) => const StatisticsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/profile',
                  builder: (_, __) => const AccountScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '/game-mode',
          builder: (context, state) {
            final args = state.extra as GameModeArgs;
            return GameModeDetailsScreen(
              title: args.title,
              subtitle: args.subtitle,
              iconPath: args.iconPath,
              color: args.color,
              isTournament: args.isTournament,
            );
          },
        ),
        GoRoute(
          path: '/game',
          // Guard against GoRouter rebuilding this route without extras (e.g.
          // when refreshListenable fires after userProvider.updateUser()).
          redirect: (_, state) => state.extra == null ? '/home' : null,
          builder: (context, state) {
            // Double-guard: the redirect above handles the common case, but
            // go_router may still invoke the builder during refreshListenable
            // evaluation. The null-safe cast ensures no crash in that window.
            final args = state.extra as GameArgs?;
            if (args == null) return const Scaffold(body: SizedBox.shrink());
            return GameScreen(
              id: args.id,
              team1: args.team1,
              team2: args.team2,
              selectedRules: args.selectedRules,
              startingTeam: args.startingTeam,
              invitations: args.invitations,
              tournamentId: args.tournamentId,
            );
          },
        ),
        GoRoute(
          path: '/tournament/:id',
          builder: (context, state) {
            final args = state.extra as TournamentPageViewArgs;
            return TournamentPageView(
              tournamentId: args.tournamentId,
              initialTournament: args.initialTournament,
            );
          },
        ),
        GoRoute(
          path: '/spectate-live/:gameId',
          builder: (context, state) {
            final gameId = state.pathParameters['gameId']!;
            return LiveGameStatsScreen(gameId: gameId);
          },
        ),
        GoRoute(
          path: '/compare',
          builder: (context, state) {
            final args = state.extra as ComparisonArgs;
            return ComparisonScreen(
              currentUser: args.currentUser,
              friend: args.friend,
            );
          },
        ),
        GoRoute(
          path: '/invitations',
          builder: (_, __) => const InvitationInboxScreen(),
        ),
        GoRoute(
          path: '/waiting',
          builder: (context, state) {
            final args = state.extra as WaitingArgs;
            return WaitingForGameScreen(args: args);
          },
        ),
      ],
    );
    return router;
  }
}
