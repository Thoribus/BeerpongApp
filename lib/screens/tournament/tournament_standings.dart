import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:flutter/material.dart';

class TournamentStandingsScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentStandingsScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    // Sort teams by wins (desc)
    final teamsSorted = [...tournament.teams];
    teamsSorted.sort((a, b) => b.wins.compareTo(a.wins));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Standings"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (int i = 0; i < teamsSorted.length; i++)
              _buildTeamStanding(context, teamsSorted[i], i + 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStanding(BuildContext context, Team team, int rank) {

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: team.color),
                const SizedBox(width: 8),
                Text(
                  'Team #$rank',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  team.players.map((p) => p.name).join(", "),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${team.wins} - ${team.losses}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: team.wins > team.losses ? Colors.green : Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTeamPlayersStats(team),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPlayersStats(Team team) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // Name
        1: FlexColumnWidth(1), // Score
        2: FlexColumnWidth(1), // Throws
        3: FlexColumnWidth(1), // Airballs
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Throws', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Airballs', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        ...team.players.map(
          (player) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(player.name),
              ),
              Text('${player.score}'),
              Text('${player.throws}'),
              Text('${player.airballs}'),
            ],
          ),
        ),
      ],
    );
  }
}
