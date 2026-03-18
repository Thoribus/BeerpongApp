//-------------Packages-------------------------
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
//----------------------------------------------

//-------------Models---------------------------
import '../../models/game_statistics.dart';
import '../../models/player.dart';
//----------------------------------------------

//-------------Screens--------------------------
import '../games/breakdown_screen.dart';
import '../games/performance_screen.dart';
import '../games/personal_statistics_screen.dart';
//----------------------------------------------

//-------------Widgets--------------------------
import '../../widgets/app_tab_bar.dart';
//----------------------------------------------

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  int _currentTabPage = 0; // Default to History tab
  late final PageController _tabPageController;

  List<GameStatistics> games = [];
  bool isLoading = true;
  bool hasError = false;
  late User user;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentTabPage);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      isLoading = false;
      return;
    }
    user = userProvider.user!;
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    try {
      games = await FirestoreService.instance.retrieveGames(user);
    } catch (e) {
      hasError = true;
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Widget _buildTabPageSelector() {
    return AppTabBar(
      tabs: const ['Stats', 'Performance', 'Breakdown', 'History'],
      selectedIndex: _currentTabPage,
      onTabSelected: (index) {
        setState(() => _currentTabPage = index);
      },
      pageController: _tabPageController,
      backgroundColor: Colors.grey.shade800,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your statistics',
                style: TextStyle(color: c.onBackground, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async => userProvider.signIn(),
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      );
    }
    user = userProvider.user!;

    if (isLoading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(
          child: Text(
            'Failed to load games',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildTabPageSelector(),
          Expanded(
            child: PageView(
              controller: _tabPageController,
              onPageChanged: (index) {
                setState(() => _currentTabPage = index);
              },
              children: [
                PersonalStatisticsScreen(user: user, games: games),
                PerformanceScreen(user: user),
                BreakdownScreen(user: user, games: games),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameStatistics game, int index) {
    final c = AppColors.of(context);
    final bool userWon = game.winningTeam == 'Team 1'
        ? game.team1Players.any((p) => p.name == user.username)
        : game.team2Players.any((p) => p.name == user.username);

    final accentColor =
        userWon ? Colors.greenAccent.shade400 : Colors.redAccent.shade200;

    final allPlayers = game.team1Players + game.team2Players;
    final userPlayer = allPlayers.where((p) => p.name == user.username).firstOrNull;
    final userHitRate = userPlayer != null && userPlayer.throws > 0
        ? (userPlayer.score / userPlayer.throws * 100).toStringAsFixed(0)
        : '--';

    final t1Cups = game.team1Players.fold(0, (s, p) => s + p.cupsHit.length);
    final t2Cups = game.team2Players.fold(0, (s, p) => s + p.cupsHit.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.15), c.card],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withValues(alpha: 0.2),
            child: Icon(
              userWon ? Icons.emoji_events : Icons.cancel,
              color: accentColor,
              size: 18,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd.MM.yy').format(game.date),
                      style: TextStyle(
                        color: c.onBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Cup scores
                  Text(
                    '$t1Cups',
                    style: TextStyle(
                      color: game.winningTeam == 'Team 1'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–',
                        style: TextStyle(color: c.subtle, fontSize: 13)),
                  ),
                  Text(
                    '$t2Cups',
                    style: TextStyle(
                      color: game.winningTeam == 'Team 2'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hit rate badge
                  if (userPlayer != null)
                    _metaBadge('$userHitRate%', Colors.amber),
                ],
              ),
              // Metadata badges row
              if (game.durationSeconds != null ||
                  game.gameMode != 'Single Game' ||
                  (game.cupsRemainingWinner != null &&
                      game.cupsRemainingWinner! >= 5) ||
                  game.specialRules.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (game.durationSeconds != null)
                        _metaBadge(
                          _formatDuration(game.durationSeconds!),
                          Colors.blueGrey,
                        ),
                      if (game.gameMode != 'Single Game')
                        _metaBadge(game.gameMode, Colors.purple),
                      if (game.cupsRemainingWinner != null &&
                          game.cupsRemainingWinner! >= 5)
                        _metaBadge(
                          '+${game.cupsRemainingWinner}',
                          Colors.green,
                        ),
                      ...game.specialRules.map(
                        (r) => _metaBadge(r, Colors.teal),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Live view',
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.white54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.push('/spectate-live/${game.id}'),
          ),
          children: [
            _buildInlinePlayerTable(context, 'Team 1', game.team1Players, mvpName: _mvpName(game)),
            const SizedBox(height: 8),
            _buildInlinePlayerTable(context, 'Team 2', game.team2Players, mvpName: _mvpName(game)),
          ],
        ),
      ),
    );
  }

  /// Returns the name of the player with the highest hit rate in [game].
  String _mvpName(GameStatistics game) {
    final all = game.team1Players + game.team2Players;
    Player? mvp;
    double best = -1;
    for (final p in all) {
      final rate = p.throws > 0 ? p.score / p.throws : 0.0;
      if (rate > best) {
        best = rate;
        mvp = p;
      }
    }
    return mvp?.name ?? '';
  }

  Widget _buildInlinePlayerTable(
      BuildContext context, String teamLabel, List<Player> players,
      {String mvpName = ''}) {
    final c = AppColors.of(context);
    final headerStyle =
        TextStyle(color: c.subtle, fontSize: 10, fontWeight: FontWeight.w600);
    final cellStyle = TextStyle(color: c.onBackground, fontSize: 11);

    const double col0 = 96; // Player name
    const double col1 = 36; // Score
    const double col2 = 42; // Throws
    const double col3 = 36; // Miss
    const double col4 = 38; // Hit%
    const double col5 = 52; // Bounce
    const double col6 = 28; // 🔥
    const double col7 = 30; // Def

    Widget cell(Widget child, double width,
            {TextAlign align = TextAlign.center}) =>
        SizedBox(width: width, child: child);

    Widget headerCell(String label, double width) =>
        cell(Text(label, style: headerStyle, textAlign: TextAlign.center), width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamLabel,
            style: TextStyle(
                color: c.subtle,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(children: [
                cell(Text('Player', style: headerStyle), col0),
                headerCell('Score', col1),
                headerCell('Throws', col2),
                headerCell('Miss', col3),
                headerCell('Hit%', col4),
                headerCell('Bounce', col5),
                headerCell('🔥', col6),
                headerCell('Def', col7),
              ]),
              const SizedBox(height: 2),
              // Data rows
              ...players.map((p) {
                final hr = p.throws > 0
                    ? '${(p.score / p.throws * 100).toStringAsFixed(0)}%'
                    : '--';
                final bounce = p.bounceAttempts > 0
                    ? '${p.bounceMakes}/${p.bounceAttempts}'
                    : '--';
                final isMvp = p.name == mvpName && mvpName.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    SizedBox(
                      width: col0,
                      child: Row(
                        children: [
                          if (isMvp)
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Text('⭐',
                                  style: TextStyle(fontSize: 10)),
                            ),
                          Expanded(
                            child: Text(
                              p.name.length > 11
                                  ? '${p.name.substring(0, 11)}…'
                                  : p.name,
                              style: isMvp
                                  ? cellStyle.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold)
                                  : cellStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    cell(Text('${p.score.toInt()}',
                        style: cellStyle, textAlign: TextAlign.center), col1),
                    cell(Text('${p.throws}',
                        style: cellStyle, textAlign: TextAlign.center), col2),
                    cell(Text('${p.misses}',
                        style: cellStyle, textAlign: TextAlign.center), col3),
                    cell(Text(hr,
                        style: cellStyle.copyWith(color: Colors.amber),
                        textAlign: TextAlign.center), col4),
                    cell(Text(bounce,
                        style: cellStyle.copyWith(color: Colors.purple.shade200),
                        textAlign: TextAlign.center), col5),
                    cell(Text('${p.onFire}',
                        style: cellStyle.copyWith(color: Colors.deepOrange),
                        textAlign: TextAlign.center), col6),
                    cell(Text('${p.defended}',
                        style: cellStyle.copyWith(color: Colors.indigo.shade200),
                        textAlign: TextAlign.center), col7),
                  ]),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    return '${m}min';
  }

  // ── Streak helpers ────────────────────────────────────────────────────────

  bool _userWonGame(GameStatistics g) => g.winningTeam == 'Team 1'
      ? g.team1Players.any((p) => p.name == user.username)
      : g.team2Players.any((p) => p.name == user.username);

  ({int length, bool isWin}) _computeCurrentStreak() {
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return (length: 0, isWin: true);
    final firstWon = _userWonGame(sorted.first);
    int count = 0;
    for (final g in sorted) {
      if (_userWonGame(g) == firstWon) {
        count++;
      } else {
        break;
      }
    }
    return (length: count, isWin: firstWon);
  }

  // ── Streak banner ─────────────────────────────────────────────────────────

  Widget _buildStreakBanner() {
    final c = AppColors.of(context);
    final streak = _computeCurrentStreak();
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    final last10 = sorted.take(10).toList();
    final wins10 = last10.where(_userWonGame).length;
    final losses10 = last10.length - wins10;
    final pct10 = last10.isEmpty ? 0 : (wins10 / last10.length * 100).round();

    final streakColor = streak.isWin ? Colors.green : Colors.redAccent;
    final streakLabel =
        '${streak.length}${streak.isWin ? 'W' : 'L'} streak';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: streakColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            streak.isWin ? Icons.local_fire_department : Icons.trending_down,
            color: streakColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Current streak: $streakLabel',
              style: TextStyle(
                color: c.onBackground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Last ${last10.length}:  ${wins10}W  ${losses10}L',
                style: TextStyle(color: c.onBackground, fontSize: 12),
              ),
              Text(
                '$pct10%',
                style: TextStyle(
                  color: wins10 >= losses10 ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final c = AppColors.of(context);
    if (games.isEmpty) {
      return Center(
        child: Text(
          'No games recorded yet.',
          style: TextStyle(color: c.subtle),
        ),
      );
    }
    return Column(
      children: [
        _buildStreakBanner(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: games.length,
            itemBuilder: (context, index) => _buildGameCard(games[index], index),
          ),
        ),
      ],
    );
  }
}

class GameDetailsPage extends StatefulWidget {
  final GameStatistics game;

  const GameDetailsPage({super.key, required this.game});

  @override
  GameDetailsPageState createState() => GameDetailsPageState();
}

class GameDetailsPageState extends State<GameDetailsPage> {
  late PageController _pageController;
  int _currentPage = 0;
  String selectedTeam = 'Both Teams';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Statistics',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _currentPage == 0
                    ? null
                    : () {
                        _pageController.jumpToPage(0);
                      },
                child: Text(
                  'View Team',
                  style: TextStyle(
                    color: _currentPage == 0 ? Colors.amber : Colors.white,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
              const VerticalDivider(
                color: Colors.white,
                width: 20,
                thickness: 2,
                indent: 5,
                endIndent: 5,
              ),
              TextButton(
                onPressed: _currentPage == 1
                    ? null
                    : () {
                        _pageController.jumpToPage(1);
                      },
                child: Text(
                  'View Game Stats',
                  style: TextStyle(
                    color: _currentPage == 1 ? Colors.amber : Colors.white,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              children: [
                _buildViewTableButton(widget.game),
                _buildGameStatsPage(widget.game),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.of(context).background,
    );
  }

  Widget _buildViewTableButton(GameStatistics game) {
    return ElevatedButton(
      onPressed: () {
        context.push('/spectate-live/${game.id}');
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
      child: const Text(
        'View Table',
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildTeamStatsTable(
    String teamName,
    Color teamColor,
    List<Player> players,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 10,
        columns: const [
          DataColumn(
            label: Text('Player', style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text('S', style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text('M', style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text('T', style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text('A', style: TextStyle(color: Colors.white)),
          ),
          DataColumn(
            label: Text('HR', style: TextStyle(color: Colors.white)),
          ),
        ],
        rows: players.map((player) {
          double hitRate = player.throws > 0 ? player.score / player.throws : 0;
          return DataRow(
            cells: [
              DataCell(SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Icon(Icons.person, color: teamColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.name.length > 10
                            ? '${player.name.substring(0, 10)}...'
                            : player.name,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.score}',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.misses}',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.throws}',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.airballs}',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  hitRate.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameStatsPage(GameStatistics game) {
    Player mvp = game.team1Players[0];
    Player airballer = game.team1Players[0];
    Player missManiac = game.team1Players[0];
    Player sniper = game.team1Players[0];

    double bestHitRate = 0;

    for (var player in game.team1Players + game.team2Players) {
      if (player.score > mvp.score) {
        mvp = player;
      }
      if (player.airballs > airballer.airballs) {
        airballer = player;
      }
      if (player.misses > missManiac.misses) {
        missManiac = player;
      }
      double hitRate = player.throws > 0 ? player.score / player.throws : 0;
      if (hitRate > bestHitRate) {
        bestHitRate = hitRate;
        sniper = player;
      }
    }

    return Container(
      color: AppColors.of(context).background,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(
                color: Colors.amber,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              _buildAchievementsSection(mvp, airballer, missManiac, sniper),
              const SizedBox(height: 20),
              const Text(
                'Team Statistics',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(
                color: Colors.amber,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              _buildTeamStatsTable('Team 1', Colors.blue, game.team1Players),
              const SizedBox(height: 20),
              _buildTeamStatsTable('Team 2', Colors.red, game.team2Players),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(
      Player mvp, Player airballer, Player missManiac, Player sniper) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAchievementIcon(Icons.star, 'MVP', mvp),
            _buildAchievementIcon(Icons.air, 'Airballer', airballer),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAchievementIcon(Icons.clear, 'Miss Maniac', missManiac),
            _buildAchievementIcon(Icons.album, 'Sniper', sniper),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementIcon(IconData icon, String title, Player player) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[800],
          child: Icon(
            icon,
            color: Colors.amber,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.amber),
        ),
        const SizedBox(height: 4),
        Text(
          player.name.length > 10
              ? '${player.name.substring(0, 10)}...'
              : player.name,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
