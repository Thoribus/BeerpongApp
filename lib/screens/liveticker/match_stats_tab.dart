import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/theme.dart';

class MatchStatsTab extends StatelessWidget {
  final LiveGameData gameData;

  const MatchStatsTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    double sumStat(List players, double Function(dynamic) f) =>
        players.fold<double>(0, (s, p) => s + f(p));

    final t1Score = sumStat(gameData.team1.players, (p) => p.score.toDouble());
    final t1Throws = sumStat(gameData.team1.players, (p) => p.throws.toDouble());
    final t1Airballs = sumStat(gameData.team1.players, (p) => p.airballs.toDouble());
    final t1Misses = sumStat(gameData.team1.players, (p) => p.misses.toDouble());
    final t1Accuracy = t1Throws > 0 ? (t1Score / t1Throws * 100).clamp(0.0, 100.0) : 0.0;

    final t2Score = sumStat(gameData.team2.players, (p) => p.score.toDouble());
    final t2Throws = sumStat(gameData.team2.players, (p) => p.throws.toDouble());
    final t2Airballs = sumStat(gameData.team2.players, (p) => p.airballs.toDouble());
    final t2Misses = sumStat(gameData.team2.players, (p) => p.misses.toDouble());
    final t2Accuracy = t2Throws > 0 ? (t2Score / t2Throws * 100).clamp(0.0, 100.0) : 0.0;

    final stats = [
      {'title': 'Score', 'team1': t1Score, 'team2': t2Score},
      {'title': 'Throws', 'team1': t1Throws, 'team2': t2Throws},
      {'title': 'Airballs', 'team1': t1Airballs, 'team2': t2Airballs},
      {'title': 'Misses', 'team1': t1Misses, 'team2': t2Misses},
      {'title': 'Accuracy %', 'team1': t1Accuracy, 'team2': t2Accuracy},
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
                color: c.surface,
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
                        style: TextStyle(
                          color: c.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stat['title'] as String,
                        style: TextStyle(
                          color: c.subtle,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        team2Value.toInt().toString(),
                        style: TextStyle(
                          color: c.onBackground,
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
