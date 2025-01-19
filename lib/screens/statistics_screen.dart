import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/live_game_stats_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
import '../models/game_statistics.dart';
import '../models/player.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  List<GameStatistics> games = [];
  bool isLoading = true;
  bool hasError = false;
  late User user;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.black,
      body: Center(
        child: ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _buildGameCard(game, index);
          },
        ),
      ),
    );
  }

  Widget _buildGameCard(GameStatistics game, int index) {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGameHeader(game, index),
            const Divider(color: Colors.grey),
            _buildTeamSection(game, 'Team 1'),
            const Divider(color: Colors.grey),
            _buildTeamSection(game, 'Team 2'),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader(GameStatistics game, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy – kk:mm').format(game.date),
              style: TextStyle(
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            _showGameDetails(game);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
          ),
          child: const Text(
            'Details',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(GameStatistics game, String team) {
    bool isWinningTeam = game.winningTeam == team;
    List<Player> players =
        team == 'Team 1' ? game.team1Players : game.team2Players;
    Color teamColor = team == 'Team 1' ? Colors.blue : Colors.red;
    List<Player> allPlayer = game.team1Players + game.team2Players;
    Player topPlayer =
        allPlayer.reduce((curr, next) => curr.score > next.score ? curr : next);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team,
                style: TextStyle(
                  color: teamColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...players.map(
                  (player) => _buildPlayerRow(player, player == topPlayer)),
            ],
          ),
        ),
        const VerticalDivider(
          color: Colors.grey,
          thickness: 1,
          width: 20,
        ),
        Icon(
          isWinningTeam ? Icons.close : Icons.flag,
          color: teamColor,
        ),
      ],
    );
  }

  Widget _buildPlayerRow(Player player, bool isTopPlayer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isTopPlayer ? BeerpongIcons.medal : Icons.person,
            size: 20,
            color: isTopPlayer ? Colors.amber : Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            '${player.cupsHit.length}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showGameDetails(GameStatistics game) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => GameDetailsPage(game: game),
    ));
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
      backgroundColor: Colors.black,
    );
  }

  Widget _buildViewTableButton(GameStatistics game) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => LiveGameStatsScreen(
              gameId: game.id),
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
