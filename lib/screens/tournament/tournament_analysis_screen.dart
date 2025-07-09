import 'dart:math' as math;

import 'package:beerpongapp/models/tournament.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TournamentAnalysisScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentAnalysisScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Win Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildWinBarChart(),
            const SizedBox(height: 24),
            const Text(
              "Score Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildScoreLineChart(),
            const SizedBox(height: 24),
            const Text(
              "Confrontation Matrix",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildConfrontationMatrix(),
          ],
        ),
      ),
    );
  }

  Widget _buildWinBarChart() {
    final barGroups = tournament.teams.asMap().entries.map((entry) {
      final index = entry.key;
      final team = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _safeDouble(team.wins.toDouble()),
            color: team.color,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < tournament.teams.length) {
                    return Text("T${index + 1}",
                        style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreLineChart() {
    final maxScore = tournament.teams
        .expand((team) => team.players)
        .fold<double>(
            0, (prev, p) => math.max(prev, _safeDouble(p.score.toDouble())));

    final spots = tournament.teams.asMap().entries.expand((entry) {
      final teamIndex = entry.key;
      final team = entry.value;
      return team.players.asMap().entries.map((playerEntry) {
        final playerIndex = playerEntry.key;
        final player = playerEntry.value;
        return FlSpot(
          (teamIndex * 2 + playerIndex).toDouble(),
          _safeDouble(player.score.toDouble()),
        );
      });
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _safeDouble(maxScore + 5),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: spots,
              dotData: FlDotData(show: true),
              color: Colors.blue,
              belowBarData: BarAreaData(show: false),
            )
          ],
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildConfrontationMatrix() {
    final teams = tournament.teams;

    return Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox(),
            ...teams
                .map((t) => Center(child: Text("T${teams.indexOf(t) + 1}"))),
          ],
        ),
        ...teams.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          return TableRow(
            children: [
              Center(child: Text("T${rowIndex + 1}")),
              ...teams.asMap().entries.map((colEntry) {
                final colIndex = colEntry.key;
                if (rowIndex == colIndex) {
                  return const Center(child: Text("✕"));
                }
                // Fake result generation (replace with real match data if available)
                final won = (rowIndex + colIndex) % 2 == 0;
                return Center(
                  child: Icon(
                    won ? Icons.check : Icons.close,
                    color: won ? Colors.green : Colors.red,
                    size: 16,
                  ),
                );
              }).toList(),
            ],
          );
        }),
      ],
    );
  }

  double _safeDouble(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 0;
    return value;
  }
}
