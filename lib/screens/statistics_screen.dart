import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/game_statistics.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import 'base_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<GameStatistics> games = [];

  @override
  void initState() {
    super.initState();
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    final databaseHelper = DatabaseHelper.instance;
    games = await databaseHelper.retrieveGames();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Card(
              color: Colors.amber.withOpacity(0.2),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Game ${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy – kk:mm')
                                  .format(game.date),
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
                    ),
                    const Divider(color: Colors.grey),
                    _buildTeamSection(game, 'Team 1'),
                    const Divider(color: Colors.grey),
                    _buildTeamSection(game, 'Team 2'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamSection(GameStatistics game, String team) {
    bool isWinningTeam = game.winningTeam == team;

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
                  color: team == 'Team 1' ? Colors.blue : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (team == 'Team 1')
                ...game.team1Players.map(
                  (player) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(player.name,
                              style: const TextStyle(color: Colors.white)),
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
                  ),
                ),
              if (team == 'Team 2')
                ...game.team2Players.map(
                  (player) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(BeerpongIcons.medal,
                            size: 20, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(player.name,
                              style: const TextStyle(color: Colors.white)),
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
                  ),
                ),
            ],
          ),
        ),
        VerticalDivider(
          color: Colors.grey,
          thickness: 1,
          width: 20,
        ),
        Icon(
          isWinningTeam ? Icons.flag : Icons.close,
          color: team == 'Team 1' ? Colors.blue : Colors.red,
        ),
      ],
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

  GameDetailsPage({required this.game});

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
                'Team Statistic',
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
              //_buildHitRateChart(game, game.team1Players),
              // You can implement _buildHitRateChart method similar to below method if needed
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

/* Widget _buildHitRateChart(GameStatistics game, List<Player> players) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Hit Rate (%)',
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
      SizedBox(
        height: 200,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: game.team1Players.length,
          itemBuilder: (context, index) {
            final player = game.team1Players;
            final hitRate = _calculateHitRate(player.score, player.throws);
            return Column(
              children: [
                Text(player.name, style: TextStyle(color: Colors.white)),
                Expanded(
                  child: CircularPercentIndicator(
                    radius: 50.0,
                    lineWidth: 10.0,
                    animation: true,
                    percent: hitRate / 1000,
                    center: Text(
                      "${hitRate.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: teamColor,
                      ),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.amber,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

// double _calculateHitRate(double score, int throws) {
  if (throws == 0) return 0.0;
  return (score / throws) * 100;
}

*/