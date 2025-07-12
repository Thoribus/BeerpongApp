import 'package:flutter/material.dart';
import 'package:beerpongapp/models/team.dart';
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
      {
        'title': 'Accuracy',
        'team1': 65.0,
        'team2': 58.0,
      },
      {
        'title': 'Rebounds',
        'team1': 12.0,
        'team2': 15.0,
      },
      {
        'title': 'Blocks',
        'team1': 3.0,
        'team2': 5.0,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Match Stats',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: stats.map((stat) {
              double team1Value = stat['team1'] as double;
              double team2Value = stat['team2'] as double;
              double maxStatValue =
                  team1Value > team2Value ? team1Value : team2Value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          team1Value.toString(),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stat['title'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          team2Value.toString(),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 10,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  left:
                                      ((team1Value + 1) / (maxStatValue + 1)) *
                                          100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: gameData.team1.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 10,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right:
                                      ((team2Value + 1) / (maxStatValue + 1)) *
                                          100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: gameData.team2.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
