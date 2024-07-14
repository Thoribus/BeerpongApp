import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/firestoreservice.dart';
import '../models/game_statistics.dart';
import '../models/player.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  List<GameStatistics> games = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    try {
      games = await FirestoreService().retrieveGames();
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

  const GameDetailsPage({Key? key, required this.game}) : super(key: key);

  @override
  _GameDetailsPageState createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showTeam1Stats = true; // Track which team stats to show

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
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showTeam1Stats = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showTeam1Stats ? Colors.blue : Colors.grey,
                ),
                child: Text('Team 1'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showTeam1Stats = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_showTeam1Stats ? Colors.red : Colors.grey,
                ),
                child: Text('Team 2'),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              children: [
                _buildTeamStatsPage(widget.game),
                _buildGameStatsPage(widget.game),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildTeamStatsPage(GameStatistics game) {
    List<Player> players =
        _showTeam1Stats ? game.team1Players : game.team2Players;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showTeam1Stats ? 'Team 1 Stats' : 'Team 2 Stats',
              style: TextStyle(
                color: _showTeam1Stats ? Colors.blue : Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(
              color: Colors.amber,
              thickness: 1,
            ),
            const SizedBox(height: 10),
            _buildDummyBarChart(), // Dummy bar chart
            const SizedBox(height: 20),
            _buildPlayerStats(players),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatsPage(GameStatistics game) {
    // Replace with your game stats page implementation if needed
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Statistics',
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
              // Add additional game stats widgets as needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDummyBarChart() {
    List<Player> players =
        _showTeam1Stats ? widget.game.team1Players : widget.game.team2Players;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTextStyles: (context, value) =>
                  const TextStyle(color: Colors.white),
              margin: 20,
              getTitles: (double value) {
                return players[value.toInt()]
                    .name
                    .substring(0, min(5, players[value.toInt()].name.length));
              },
            ),
            leftTitles: SideTitles(showTitles: false),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  y: players[0].score.toDouble(),
                  //color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStats(List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: players.map((player) => _buildPlayerRow(player)).toList(),
    );
  }

  Widget _buildPlayerRow(Player player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: _showTeam1Stats ? Colors.blue : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            player.name,
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Text(
            'Score: ${player.score}',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 16),
          Text(
            'Misses: ${player.misses}',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
