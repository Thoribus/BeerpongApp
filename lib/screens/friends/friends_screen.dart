import 'dart:async';

import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:beerpongapp/util/route_args.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_tab_bar.dart';
import 'package:beerpongapp/util/localization_extensions.dart';

enum _FeedEventType { sharedGame, winStreak, achievement, friendActive }

class _FeedEvent {
  const _FeedEvent({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.friend,
    this.game,
    this.userWon,
  });

  final _FeedEventType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final User? friend; // null for winStreak
  final GameStatistics? game; // for sharedGame
  final bool? userWon; // for sharedGame
}

enum _SortKey { totalScore, winRate, hitRate, onFire, bounceRate, gamesPlayed }

extension _SortKeyLabel on _SortKey {
  String label(AppLocalizations l) => switch (this) {
        _SortKey.totalScore => l.leaderboardTotalScore,
        _SortKey.winRate => l.statsWinRate,
        _SortKey.hitRate => l.statsHitRate,
        _SortKey.onFire => l.statsOnFire,
        _SortKey.bounceRate => l.compareBouncePercent,
        _SortKey.gamesPlayed => l.leaderboardGames,
      };
}

/// Returns a human-readable relative time string, e.g. "just now", "3d ago".
String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

double _sortValue(_SortKey key, User u) {
  switch (key) {
    case _SortKey.totalScore:
      return u.totalScore;
    case _SortKey.winRate:
      return u.winRate;
    case _SortKey.hitRate:
      return u.hitRate;
    case _SortKey.onFire:
      return u.onFire.toDouble();
    case _SortKey.bounceRate:
      return u.bounceAttempts > 0
          ? u.bounceMakes / u.bounceAttempts
          : 0;
    case _SortKey.gamesPlayed:
      return (u.wins + u.losses).toDouble();
  }
}

String _sortDisplay(_SortKey key, User u) {
  switch (key) {
    case _SortKey.totalScore:
      return u.totalScore.toInt().toString();
    case _SortKey.winRate:
      return '${(u.winRate * 100).toStringAsFixed(1)}%';
    case _SortKey.hitRate:
      return '${(u.hitRate * 100).toStringAsFixed(1)}%';
    case _SortKey.onFire:
      return u.onFire.toString();
    case _SortKey.bounceRate:
      return u.bounceAttempts > 0
          ? '${(u.bounceMakes / u.bounceAttempts * 100).toStringAsFixed(0)}%'
          : '--';
    case _SortKey.gamesPlayed:
      return '${u.wins + u.losses}';
  }
}

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({
    super.key,
    this.friendsLoader,
    this.gamesLoader,
  });

  /// Optional loader override for tests to avoid direct Firestore calls.
  final Future<List<User>> Function(String userId)? friendsLoader;

  /// Optional loader override for tests to avoid direct Firestore calls.
  final Future<List<GameStatistics>> Function(User user)? gamesLoader;

  @override
  FriendsListScreenState createState() => FriendsListScreenState();
}

class FriendsListScreenState extends State<FriendsListScreen> {
  Future<List<User>>? _friends;
  Future<List<User>>? _friendsWithUser;
  Future<List<GameStatistics>>? _myGames;
  _SortKey _sortKey = _SortKey.totalScore;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  StreamSubscription<List<String>>? _friendIdsSub;
  List<String>? _lastKnownFriendIds;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null && _friends == null) {
      final loadFriends =
          widget.friendsLoader ?? FirestoreService.instance.getFriends;
      final loadGames =
          widget.gamesLoader ?? FirestoreService.instance.retrieveGames;

      _friends = loadFriends(user.id);
      _friendsWithUser = _friends!.then((friends) => [user, ...friends]);
      _myGames = loadGames(user);

      // Watch the current user's friends array for remote changes (e.g. when
      // someone else adds this user). Skip the first emission — it duplicates
      // the initial load above.
      _friendIdsSub ??= FirestoreService.instance
          .streamFriendIds(user.id)
          .skip(1)
          .listen((ids) {
        if (!mounted) return;
        // Only refresh when the set of IDs actually changed.
        final changed = _lastKnownFriendIds == null ||
            ids.length != _lastKnownFriendIds!.length ||
            ids.toSet().difference(_lastKnownFriendIds!.toSet()).isNotEmpty;
        _lastKnownFriendIds = ids;
        if (changed) _refreshFriendsOnly(userProvider);
      });
    }
  }

  @override
  void dispose() {
    _friendIdsSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Prompts the user to add a friend by ID or by scanning a QR code.
  Future<void> _showAddFriendDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _showErrorSnackBar(context.loc.friendsMustSignIn);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AddFriendDialog(
        currentUser: userProvider.user!,
        onAddById: (friendId) => _addFriend(context, friendId, userProvider),
        onScanQr: () => _scanQRCode(ctx),
      ),
    );
  }

  /// Scans a QR code and attempts to add a friend with the scanned ID.
  Future<void> _scanQRCode(BuildContext dialogCtx) async {
    try {
      final result = await BarcodeScanner.scan();
      if (!mounted) return;
      if (result.type == ResultType.Barcode) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await _addFriend(context, result.rawContent, userProvider);
        if (!mounted) return;
        if (dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop(); // close the dialog
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning QR code: $e');
    }
  }

  /// Adds a friend by ID, refreshes the Future list.
  Future<void> _addFriend(
    BuildContext ctx,
    String friendId,
    UserProvider userProvider,
  ) async {
    try {
      await FirestoreService.instance
          .addFriend(userProvider.user!.id, friendId);
      _refreshFriends(userProvider);
    } catch (e) {
      _showErrorSnackBar('Error adding friend: $e');
    }
  }

  /// Removes a friend (symmetric), refreshes the Future list.
  Future<void> _removeFriend(User friend) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await FirestoreService.instance
          .removeFriend(userProvider.user!.id, friend.id);
      _refreshFriends(userProvider);
    } catch (e) {
      _showErrorSnackBar('Error removing friend: $e');
    }
  }

  void _refreshFriends(UserProvider userProvider) {
    // Games are unaffected by friend add/remove — only reload the friend list.
    _refreshFriendsOnly(userProvider);
  }

  void _refreshFriendsOnly(UserProvider userProvider) {
    setState(() {
      final loadFriends =
          widget.friendsLoader ?? FirestoreService.instance.getFriends;
      _friends = loadFriends(userProvider.user!.id);
      _friendsWithUser =
          _friends!.then((friends) => [userProvider.user!, ...friends]);
    });
  }

  /// Shows a red error SnackBar with the given message.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Navigates to the comparison screen for the friend and the current user.
  void _showComparisonScreen(User friend) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _showErrorSnackBar('You must be signed in to view comparisons.');
      return;
    }

    context.push(AppRoutes.compare,
        extra: ComparisonArgs(
          currentUser: userProvider.user!,
          friend: friend,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final c = AppColors.of(context);

    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                context.loc.friendsSignInPrompt,
                style: TextStyle(color: c.onBackground, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async => userProvider.signIn(),
                child: Text(context.loc.btnSignInGoogle),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          _buildPageSelector(),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildFriendsListPage(),
                _buildRankingPage(),
                _buildSocialPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelector() {
    return AppTabBar(
      tabs: [context.loc.friendsTabFriendlist, context.loc.friendsTabLeaderboard, context.loc.friendsTabSocials],
      selectedIndex: _currentPage,
      onTabSelected: (index) {
        if (_currentPage != index) {
          _pageController.jumpToPage(index);
        }
      },
      backgroundColor: Colors.grey.shade800,
    );
  }

  Widget _buildFriendsListPage() {
    return FutureBuilder<List<Object>>(
      future: Future.wait([_friends!, _myGames!]),
      builder: (context, snapshot) {
        final c = AppColors.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(context.loc.liveGameError,
                style: TextStyle(color: c.onBackground)),
          );
        }
        final friends = snapshot.data![0] as List<User>;
        final myGames = snapshot.data![1] as List<GameStatistics>;
        final userProvider = Provider.of<UserProvider>(context);
        final currentUserId = userProvider.user?.id ?? '';

        // Pre-compute H2H map once — avoids O(friends × games) linear scan
        // inside itemBuilder on every frame.
        final h2hByFriend = <String, List<GameStatistics>>{};
        for (final g in myGames) {
          for (final pid in g.participants) {
            if (pid == currentUserId) continue;
            (h2hByFriend[pid] ??= []).add(g);
          }
        }
        for (final list in h2hByFriend.values) {
          list.sort((a, b) => b.date.compareTo(a.date));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            if (userProvider.user != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: c.card,
                elevation: 1,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: _buildCompactFriendAvatar(userProvider.user!),
                  title: Text(
                    userProvider.user!.username,
                    style: TextStyle(fontSize: 14, color: c.onBackground),
                  ),
                  subtitle: Text(
                    'Title: ${userProvider.user!.title}',
                    style: TextStyle(fontSize: 12, color: c.subtle),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _showAddFriendDialog(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      radius: 16,
                      child: Icon(Icons.add, color: Colors.black, size: 16),
                    ),
                  ),
                  onTap: () => _showComparisonScreen(userProvider.user!),
                ),
              ),
            const SizedBox(height: 10),
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.loc.friendsNoFriends,
                    style: TextStyle(color: c.subtle, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              itemBuilder: (ctx, index) {
                final friend = friends[index];
                final h2hGames = h2hByFriend[friend.id] ?? [];
                return FriendTile(
                  friend: friend,
                  currentUserId: currentUserId,
                  h2hGames: h2hGames,
                  onTap: () => _showComparisonScreen(friend),
                  onRemove: () => _removeFriend(friend),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Social feed — pure computation (no extra Firestore calls)
  // ---------------------------------------------------------------------------

  List<_FeedEvent> _buildFeedEvents(
    List<User> friends,
    List<GameStatistics> myGames,
    String currentUserId,
    AppLocalizations l,
  ) {
    final events = <_FeedEvent>[];
    final friendById = {for (final f in friends) f.id: f};

    // 1. Shared-game events — one card per (game × friend who participated)
    for (final game in myGames) {
      for (final participantId in game.participants) {
        if (participantId == currentUserId) continue;
        final friend = friendById[participantId];
        if (friend == null) continue;

        final onTeam1 =
            game.team1Players.any((p) => p.user?.id == currentUserId);
        final userWon = game.winningTeam == (onTeam1 ? 'Team 1' : 'Team 2');

        final myTeam = onTeam1 ? game.team1Players : game.team2Players;
        final oppTeam = onTeam1 ? game.team2Players : game.team1Players;

        final myScore = myTeam.fold<double>(0, (s, p) => s + p.score).toInt();
        final oppScore = oppTeam.fold<double>(0, (s, p) => s + p.score).toInt();

        final myPlayers =
            myTeam.where((p) => p.user?.id == currentUserId).toList();
        final hitPct = myPlayers.isNotEmpty && myPlayers.first.throws > 0
            ? (myPlayers.first.score / myPlayers.first.throws * 100).round()
            : 0;

        events.add(_FeedEvent(
          type: _FeedEventType.sharedGame,
          date: game.date,
          title: userWon
              ? l.socialBeatFriend(friend.username)
              : l.socialLostToFriend(friend.username),
          subtitle: l.socialSharedGameResult(myScore, oppScore, hitPct),
          friend: friend,
          game: game,
          userWon: userWon,
        ));
      }
    }

    // 2. Current-user win streak (≥ 3)
    final sorted = [...myGames]..sort((a, b) => b.date.compareTo(a.date));
    var streak = 0;
    for (final g in sorted) {
      final onTeam1 = g.team1Players.any((p) => p.user?.id == currentUserId);
      final won = g.winningTeam == (onTeam1 ? 'Team 1' : 'Team 2');
      if (won) {
        streak++;
      } else {
        break;
      }
    }
    if (streak >= 3) {
      events.add(_FeedEvent(
        type: _FeedEventType.winStreak,
        date: sorted.isNotEmpty ? sorted.first.date : DateTime.now(),
        title: l.socialWinStreak(streak),
        subtitle: l.socialWinStreakSubtitle,
      ));
    }

    // 3. Friend achievements — highest milestone only per category per friend
    const winMilestones = [200, 100, 50, 25, 10];
    const fireMilestones = [100, 50, 25];
    for (final friend in friends) {
      for (final m in winMilestones) {
        if (friend.wins >= m) {
          events.add(_FeedEvent(
            type: _FeedEventType.achievement,
            date: friend.lastGameAt ?? DateTime.now(),
            title: l.socialFriendReachedWins(friend.username, m),
            subtitle: l.socialFriendLegendSubtitle,
            friend: friend,
          ));
          break;
        }
      }
      for (final m in fireMilestones) {
        if (friend.onFire >= m) {
          events.add(_FeedEvent(
            type: _FeedEventType.achievement,
            date: friend.lastGameAt ?? DateTime.now(),
            title: l.socialFriendOnFire(friend.username, m),
            subtitle: l.socialSeriousHeatSubtitle,
            friend: friend,
          ));
          break;
        }
      }
    }

    // 4. Friends active in the last 3 days
    for (final friend in friends) {
      if (friend.lastGameAt != null &&
          DateTime.now().difference(friend.lastGameAt!).inDays <= 3) {
        events.add(_FeedEvent(
          type: _FeedEventType.friendActive,
          date: friend.lastGameAt!,
          title: l.socialFriendIsActive(friend.username),
          subtitle: l.socialFriendActiveSubtitle(
              _timeAgo(friend.lastGameAt!), friend.wins + friend.losses),
          friend: friend,
        ));
      }
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  Widget _buildSocialPage() {
    return FutureBuilder<List<Object>>(
      future: Future.wait([_friends!, _myGames!]),
      builder: (context, snapshot) {
        final c = AppColors.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(context.loc.liveGameError,
                  style: TextStyle(color: c.onBackground)));
        }

        final friends = snapshot.data![0] as List<User>;
        final myGames = snapshot.data![1] as List<GameStatistics>;
        final currentUserId =
            Provider.of<UserProvider>(context, listen: false).user?.id ?? '';

        final events = _buildFeedEvents(friends, myGames, currentUserId, context.loc);

        if (events.isEmpty && friends.isEmpty) {
          return Center(
            child: Text(context.loc.friendsNoActivity,
                style: TextStyle(color: c.subtle)),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            if (events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(context.loc.friendsNoRecentActivity,
                      style: TextStyle(color: c.subtle)),
                ),
              )
            else
              ...events.map((e) => _buildFeedCard(context, e)),
          ],
        );
      },
    );
  }

  Widget _buildFeedCard(BuildContext context, _FeedEvent event) {
    final c = AppColors.of(context);

    switch (event.type) {
      // ── Shared game ────────────────────────────────────────────────────
      case _FeedEventType.sharedGame:
        final won = event.userWon ?? false;
        final accent = won ? Colors.green : Colors.red.shade700;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (event.friend != null)
                  _buildCompactFriendAvatar(event.friend!),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.onBackground,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              won ? 'W' : 'L',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(event.subtitle,
                          style: TextStyle(fontSize: 11, color: c.subtle)),
                      const SizedBox(height: 6),
                      Text(_timeAgo(event.date),
                          style: TextStyle(fontSize: 10, color: c.subtle)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      // ── Win streak ─────────────────────────────────────────────────────
      case _FeedEventType.winStreak:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade800,
                Colors.amber.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(event.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        );

      // ── Achievement ────────────────────────────────────────────────────
      case _FeedEventType.achievement:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border(
                left: BorderSide(color: Colors.amber.shade700, width: 3)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: event.friend != null
                ? _buildCompactFriendAvatar(event.friend!)
                : const Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(event.title,
                style: TextStyle(
                    fontSize: 13,
                    color: c.onBackground,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(event.subtitle,
                style: TextStyle(fontSize: 11, color: c.subtle)),
            trailing: Text(_timeAgo(event.date),
                style: TextStyle(fontSize: 10, color: c.subtle)),
            onTap: event.friend != null
                ? () => _showComparisonScreen(event.friend!)
                : null,
          ),
        );

      // ── Friend active ──────────────────────────────────────────────────
      case _FeedEventType.friendActive:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border:
                Border(left: BorderSide(color: Colors.blue.shade400, width: 3)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: event.friend != null
                ? _buildCompactFriendAvatar(event.friend!, isActive: true)
                : null,
            title: Text(event.title,
                style: TextStyle(
                    fontSize: 13,
                    color: c.onBackground,
                    fontWeight: FontWeight.w600)),
            subtitle: Text(event.subtitle,
                style: TextStyle(fontSize: 11, color: c.subtle)),
            trailing: Text(_timeAgo(event.date),
                style: TextStyle(fontSize: 10, color: c.subtle)),
            onTap: event.friend != null
                ? () => _showComparisonScreen(event.friend!)
                : null,
          ),
        );
    }
  }

  /// Builds the “Leaderboard” page, which includes the user + friends sorted by an attribute.
  Widget _buildRankingPage() {
    return FutureBuilder<List<User>>(
      future: _friendsWithUser,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(context.loc.liveGameError));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(context.loc.friendsNoFriendsFound));
        }

        final friends = snapshot.data!;
        friends.sort((a, b) =>
            _sortValue(_sortKey, b).compareTo(_sortValue(_sortKey, a)));

        return Column(
          children: [
            _buildPodium(friends),
            _buildSortingChips(),
            Expanded(child: _buildRankingList(friends)),
          ],
        );
      },
    );
  }

  Widget _buildPodium(List<User> friends) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[800], // Fallback background color
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // SVG Background
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/podium_background.svg', // Replace with your SVG path
                  fit: BoxFit.cover,
                ),
              ),

              // Second place (Left)
              if (friends.length > 1)
                Positioned(
                  left: 40,
                  bottom: 100, // Adjust height of podium
                  child:
                      _buildPodiumUser(friends[1], 2, Colors.blue, height: 100),
                ),

              // First place (Center, Highest)
              if (friends.isNotEmpty)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 50, // Center
                  bottom: 130, // Highest podium height
                  child: _buildPodiumUser(friends[0], 1, Colors.amber,
                      crown: true, height: 120),
                ),

              // Third place (Right)
              if (friends.length > 2)
                Positioned(
                  right: 20,
                  bottom: 90, // Lowest podium position
                  child:
                      _buildPodiumUser(friends[2], 3, Colors.green, height: 80),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumUser(User user, int rank, Color borderColor,
      {bool crown = false, double height = 100}) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: borderColor,
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Colors.black,
                child: ClipOval(
                  child: user.mapAvatarKeyToAsset().isEmpty
                      ? const Icon(Icons.person,
                          size: 38, color: Colors.white54)
                      : SvgPicture.asset(
                          user.mapAvatarKeyToAsset(),
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            if (crown)
              const Positioned(
                top: -5,
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            user.username,
            style: TextStyle(color: c.onBackground),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          _sortDisplay(_sortKey, user),
          style: TextStyle(color: c.onBackground, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSortingChips() {
    final c = AppColors.of(context);
    return Container(
      color: c.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _SortKey.values.map((key) {
            final selected = _sortKey == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(key.label(context.loc)),
                selected: selected,
                onSelected: (_) => setState(() => _sortKey = key),
                selectedColor: Colors.amber,
                backgroundColor: c.card,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : c.onBackground,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                checkmarkColor: Colors.black,
                side: BorderSide(
                  color: selected ? Colors.amber : Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRankingList(List<User> friends) {
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).user?.id;
    final c = AppColors.of(context);
    return ListView.builder(
      itemCount: (friends.length - 3).clamp(0, friends.length),
      itemBuilder: (ctx, index) {
        final u = friends[index + 3];
        final isMe = u.id == currentUserId;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: isMe
              ? BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: ListTile(
            leading: Text(
              '${index + 4}',
              style: TextStyle(
                color: isMe ? Colors.amber : c.subtle,
                fontSize: 16,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            title: Row(
              children: [
                _buildFriendAvatar(u, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMe ? '${u.username} (you)' : u.username,
                    style: TextStyle(
                      color: isMe ? Colors.amber : c.onBackground,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Text(
              _sortDisplay(_sortKey, u),
              style: TextStyle(
                color: isMe ? Colors.amber : c.subtle,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendAvatar(User friend, {double radius = 30}) {
    final assetPath = friend.mapAvatarKeyToAsset();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: ClipOval(
        child: assetPath.isEmpty
            ? Icon(Icons.person, size: radius, color: Colors.white54)
            : SvgPicture.asset(
                assetPath,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
              ),
      ),
    );
  }

  Widget _buildCompactFriendAvatar(User user, {bool isActive = false}) =>
      _FriendAvatar(user: user, isActive: isActive);
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets (public so they can be tested directly)
// ---------------------------------------------------------------------------

/// Compact circular avatar with an optional green "active" dot.
class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.user, this.isActive = false});

  final User user;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final assetPath = user.mapAvatarKeyToAsset();
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white24,
      child: ClipOval(
        child: assetPath.isEmpty
            ? const Icon(Icons.person, size: 20, color: Colors.white54)
            : SvgPicture.asset(assetPath,
                fit: BoxFit.cover, width: 40, height: 40),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: ClipOval(child: avatar),
        ),
        if (isActive)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              key: const Key('active-dot'),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Self-contained friend card with H2H chip, form strip, and swipe-to-dismiss.
/// All computed data is passed in so the widget can be unit-tested without
/// a Firestore connection.
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    required this.currentUserId,
    required this.h2hGames,
    required this.onTap,
    required this.onRemove,
  });

  final User friend;
  final String currentUserId;

  /// Games played between [currentUserId] and [friend.id], newest first.
  final List<GameStatistics> h2hGames;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  bool get _isActive =>
      friend.lastGameAt != null &&
      DateTime.now().difference(friend.lastGameAt!).inDays <= 7;

  ({int wins, int losses}) get _h2h {
    int wins = 0, losses = 0;
    for (final g in h2hGames) {
      final onTeam1 = g.team1Players.any((p) => p.user?.id == currentUserId);
      final won = g.winningTeam == (onTeam1 ? 'Team 1' : 'Team 2');
      if (won) {
        wins++;
      } else {
        losses++;
      }
    }
    return (wins: wins, losses: losses);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final h2h = _h2h;
    final recent5 = h2hGames.take(5).toList();
    final lastSeen =
        friend.lastGameAt != null ? _timeAgo(friend.lastGameAt!) : 'No games';

    return Dismissible(
      key: Key(friend.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(context.loc.friendsRemoveTitle),
            content: Text(context.loc.friendsRemoveBody(friend.username)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(context.loc.btnCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: Text(context.loc.friendsRemoveConfirm,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person_remove, color: Colors.white),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: c.card,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _FriendAvatar(user: friend, isActive: _isActive),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.username,
                        style: TextStyle(
                            fontSize: 13,
                            color: c.onBackground,
                            fontWeight: FontWeight.w600),
                      ),
                      if (friend.title.isNotEmpty)
                        Text(friend.title,
                            style: TextStyle(fontSize: 11, color: c.subtle)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (h2hGames.isNotEmpty)
                            Container(
                              key: const Key('h2h-chip'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.surface2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'H2H  W${h2h.wins} · L${h2h.losses}',
                                style: TextStyle(
                                    fontSize: 10, color: c.onBackground),
                              ),
                            ),
                          const SizedBox(width: 6),
                          ...recent5.map((g) {
                            final onTeam1 = g.team1Players
                                .any((p) => p.user?.id == currentUserId);
                            final won = g.winningTeam ==
                                (onTeam1 ? 'Team 1' : 'Team 2');
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: won ? Colors.green : Colors.red.shade700,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (friend.activeGameId != null &&
                        friend.activeGameId!.isNotEmpty)
                      TextButton.icon(
                        key: const Key('watch-btn'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon:
                            const Icon(Icons.remove_red_eye_outlined, size: 14),
                        label: Text(context.loc.friendsWatchBtn,
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () => context.push(
                            AppRoutes.spectateLobbyPath(
                                friend.activeGameId!)),
                      )
                    else ...[
                      Text('last seen',
                          style: TextStyle(fontSize: 10, color: c.subtle)),
                      const SizedBox(height: 2),
                      Text(
                        lastSeen,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: c.onBackground,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-Friend dialog with username search + QR section
// ---------------------------------------------------------------------------

class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog({
    required this.currentUser,
    required this.onAddById,
    required this.onScanQr,
  });

  final User currentUser;
  final void Function(String friendId) onAddById;
  final VoidCallback onScanQr;

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<User>>? _results;
  bool _qrExpanded = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _results = FirestoreService.instance.searchUsers(
          query.trim(),
          excludeId: widget.currentUser.id,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: c.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────────
                Text(
                  context.loc.friendsAddTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.onBackground,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Search field ─────────────────────────────────────
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: context.loc.friendsSearchHint,
                    hintStyle: TextStyle(fontSize: 14, color: c.subtle),
                    prefixIcon: Icon(Icons.search, color: c.subtle, size: 20),
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.orange, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Colors.deepOrange, width: 1.5),
                    ),
                  ),
                  style: TextStyle(fontSize: 14, color: c.onBackground),
                ),
                const SizedBox(height: 10),

                // ── Search results ───────────────────────────────────
                if (_results != null)
                  FutureBuilder<List<User>>(
                    future: _results,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }
                      final users = snap.data ?? [];
                      if (users.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.person_search,
                                  color: c.subtle, size: 18),
                              const SizedBox(width: 8),
                              Text(context.loc.friendsNoUsersFound,
                                  style:
                                      TextStyle(color: c.subtle, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final alreadyFriend =
                              widget.currentUser.friends.contains(u.id);
                          return ListTile(
                            dense: true,
                            leading: _FriendAvatar(user: u),
                            title: Text(u.username,
                                style: TextStyle(
                                    fontSize: 13, color: c.onBackground)),
                            subtitle: u.title.isNotEmpty
                                ? Text(u.title,
                                    style: TextStyle(
                                        fontSize: 11, color: c.subtle))
                                : null,
                            trailing: alreadyFriend
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20)
                                : TextButton(
                                    onPressed: () {
                                      widget.onAddById(u.id);
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.orange),
                                    child: Text(context.loc.friendsAddBtn),
                                  ),
                          );
                        },
                      );
                    },
                  ),

                // ── QR section (collapsible) ─────────────────────────
                const Divider(height: 20),
                GestureDetector(
                  onTap: () => setState(() => _qrExpanded = !_qrExpanded),
                  child: Row(
                    children: [
                      Icon(
                        _qrExpanded ? Icons.expand_less : Icons.expand_more,
                        color: c.subtle,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(context.loc.friendsShareQr,
                          style: TextStyle(fontSize: 13, color: c.subtle)),
                    ],
                  ),
                ),
                if (_qrExpanded) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final messenger = ScaffoldMessenger.of(context);
                        final copiedMsg = context.loc.friendsIdCopied;
                        Clipboard.setData(
                                ClipboardData(text: widget.currentUser.id))
                            .then((_) => messenger.showSnackBar(
                                  SnackBar(content: Text(copiedMsg)),
                                ));
                      },
                      child: Text(
                        'ID: ${widget.currentUser.id}',
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: QrImageView(
                        data: widget.currentUser.id,
                        version: QrVersions.auto,
                        size: MediaQuery.of(context).size.width * 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: widget.onScanQr,
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: Text(context.loc.friendsScanQrBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                // ── Close ────────────────────────────────────────────
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text(context.loc.btnClose, style: TextStyle(color: c.onBackground)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
