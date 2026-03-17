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
      tabs: const ['Stats', 'Performance', 'History'],
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
          title: Row(
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
                child:
                    Text('–', style: TextStyle(color: c.subtle, fontSize: 13)),
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
              // Your hit rate badge
              if (userPlayer != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$userHitRate%',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
            _buildInlinePlayerTable(context, 'Team 1', game.team1Players),
            const SizedBox(height: 8),
            _buildInlinePlayerTable(context, 'Team 2', game.team2Players),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePlayerTable(
      BuildContext context, String teamLabel, List<Player> players) {
    final c = AppColors.of(context);
    final headerStyle =
        TextStyle(color: c.subtle, fontSize: 10, fontWeight: FontWeight.w600);
    final cellStyle = TextStyle(color: c.onBackground, fontSize: 11);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(teamLabel,
            style: TextStyle(
                color: c.subtle,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              children: [
                Text('Player', style: headerStyle),
                Text('Score', style: headerStyle, textAlign: TextAlign.center),
                Text('Throws', style: headerStyle, textAlign: TextAlign.center),
                Text('Miss', style: headerStyle, textAlign: TextAlign.center),
                Text('Hit%', style: headerStyle, textAlign: TextAlign.center),
              ],
            ),
            ...players.map((p) {
              final hr = p.throws > 0
                  ? '${(p.score / p.throws * 100).toStringAsFixed(0)}%'
                  : '--';
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      p.name.length > 12
                          ? '${p.name.substring(0, 12)}…'
                          : p.name,
                      style: cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${p.score.toInt()}',
                      style: cellStyle, textAlign: TextAlign.center),
                  Text('${p.throws}',
                      style: cellStyle, textAlign: TextAlign.center),
                  Text('${p.misses}',
                      style: cellStyle, textAlign: TextAlign.center),
                  Text(hr,
                      style: cellStyle.copyWith(color: Colors.amber),
                      textAlign: TextAlign.center),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (games.isEmpty) {
      return Center(
        child: Text(
          'No games recorded yet.',
          style: TextStyle(color: AppColors.of(context).subtle),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: games.length,
      itemBuilder: (context, index) => _buildGameCard(games[index], index),
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
