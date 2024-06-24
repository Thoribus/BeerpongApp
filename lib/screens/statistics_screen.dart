import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/firestoreservice.dart';
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
              ...players
                  .map((player) => _buildPlayerRow(player, player == topPlayer)),
            ],
          ),
        ),
        const VerticalDivider(
          color: Colors.grey,
          thickness: 1,
          width: 20,
        ),
        Icon(
          isWinningTeam ? Icons.flag : Icons.close,
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

class GameDetailsPage extends StatelessWidget {
  final GameStatistics game;

  const GameDetailsPage({super.key, required this.game});

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
      body: _buildGameStatsPage(game),
    );
  }

  Widget _buildGameStatsPage(GameStatistics game) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

  Widget _buildTeamStatsTable(
      String teamName, Color teamColor, List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(
            color: teamColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        DataTable(
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
          ],
          rows: players.map((player) {
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  Icon(Icons.person, color: teamColor),
                  const SizedBox(width: 8),
                  Text(player.name,
                      style: const TextStyle(color: Colors.white)),
                ],
              )),
              DataCell(Text('${player.score}',
                  style: const TextStyle(color: Colors.white))),
              DataCell(Text('${player.misses}',
                  style: const TextStyle(color: Colors.white))),
              DataCell(Text('${player.throws}',
                  style: const TextStyle(color: Colors.white))),
              DataCell(Text('${player.airballs}',
                  style: const TextStyle(color: Colors.white))),
            ]);
          }).toList(),
        ),
      ],
    );
  }
}
