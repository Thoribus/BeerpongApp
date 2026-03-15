import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';

class MatchStatsTab extends StatelessWidget {
  final LiveGameData gameData;

  const MatchStatsTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Score',
        'team1': gameData.team1.players[0].score.toDouble(),
        'team2': gameData.team2.players[0].score.toDouble()
      },
      {
        'title': 'Throws',
        'team1': gameData.team1.players[0].throws.toDouble(),
        'team2': gameData.team2.players[0].throws.toDouble()
      },
      {
        'title': 'Airballs',
        'team1': gameData.team1.players[0].airballs.toDouble(),
        'team2': gameData.team2.players[0].airballs.toDouble()
      },
      {
        'title': 'Misses',
        'team1': gameData.team1.players[0].misses.toDouble(),
        'team2': gameData.team2.players[0].misses.toDouble()
      },
      {'title': 'Accuracy', 'team1': 65.0, 'team2': 58.0},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...stats.map((stat) {
            final double team1Value = stat['team1'] as double;
            final double team2Value = stat['team2'] as double;
            final double maxValue =
                (team1Value > team2Value ? team1Value : team2Value)
                    .clamp(1, double.infinity);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        team1Value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white, //Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stat['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        team2Value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white, // Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: (team1Value / maxValue * 100).toInt(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: gameData.team1.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: (team2Value / maxValue * 100).toInt(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: gameData.team2.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
