//-------------Packages-------------------------
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
//----------------------------------------------

//-------------Models---------------------------
import '../../models/game_statistics.dart';
import '../../models/player.dart';
//----------------------------------------------

//-------------Screens--------------------------
import '../games/performance_screen.dart';
import '../games/personal_statistics_screen.dart';
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
      games = await FirestoreService().retrieveGames(user);
    } catch (e) {
      hasError = true;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildTabPageSelector() {
    final List<String> tabs = ['Stats', 'Performance', 'History'];

    return Container(
      height: 48,
      width: double.infinity,
      color: Colors.grey.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTabPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() => _currentTabPage = index);
                  _tabPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Sign in to view your statistics',
                style: TextStyle(color: Colors.white, fontSize: 16),
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
                PersonalStatisticsScreen(user: user),
                PerformanceScreen(user: user),
                _buildHistoryTab(), // Your original content
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameStatistics game, int index) {
    final bool userWon = (game.winningTeam == 'Team 1'
        ? game.team1Players.any((p) => p.name == user.username)
        : game.team2Players.any((p) => p.name == user.username));

    final Color winColor = Colors.greenAccent.shade400;
    final Color loseColor = Colors.redAccent.shade200;

    int team1Cups =
        game.team1Players.fold(0, (sum, p) => sum + p.cupsHit.length);
    int team2Cups =
        game.team2Players.fold(0, (sum, p) => sum + p.cupsHit.length);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: userWon
                  ? [winColor, Colors.white]
                  : [loseColor, Colors.white],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(4, 6), // bottom-right style
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Top Row: Game title + Win/Lose icon (left), Date centered
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        userWon ? Icons.emoji_events : Icons.cancel,
                        color: userWon
                            ? Colors.green.shade700
                            : Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Game ${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy – kk:mm').format(game.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Avatars Row with Team CupsHit on edges
              Row(
                children: [
                  /// Team 1 CupsHit - left aligned
                  Text(
                    '$team1Cups',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  /// Centered avatars + VS
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ..._buildAvatarList(context, game.team1Players),
                        const SizedBox(width: 12),
                        const Text('VS',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ..._buildAvatarList(context, game.team2Players),
                      ],
                    ),
                  ),

                  /// Team 2 CupsHit - right aligned
                  Text(
                    '$team2Cups',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        /// Floating details button in top-right
        Positioned(
          top: 4,
          right: 8,
          child: IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => LiveGameStatsScreen(gameId: game.id),
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(game, index);
      },
    );
  }
}

List<Widget> _buildAvatarList(BuildContext context, List<dynamic> players) {
  return players.map((player) {
    String? avatarPath;
    int cupsHitCount = 0;
    String playerName = 'Unknown';
    User? user = player.user;

    if (user != null) {
      if (user.avatarKey.isNotEmpty) {
        avatarPath = user.mapAvatarKeyToAsset();
      }
    }

    cupsHitCount = player.cupsHit?.length ?? 0;
    playerName = player.name;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(playerName),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: avatarPath != null && avatarPath.isNotEmpty
                  ? ClipOval(
                      child: SvgPicture.asset(
                        avatarPath,
                        fit: BoxFit.cover,
                        width: 32,
                        height: 32,
                      ),
                    )
                  : const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '$cupsHitCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }).toList();
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
      backgroundColor: Colors.black,
    );
  }

  Widget _buildViewTableButton(GameStatistics game) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LiveGameStatsScreen(gameId: game.id),
        ));
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
      color: Colors.black,
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
