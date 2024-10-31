import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:beerpongapp/models/user.dart';

class PersonalStatisticsScreen extends StatelessWidget {
  final User user;

  const PersonalStatisticsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Statistics"),
      ),
      body: SingleChildScrollView(
        // Make the screen scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            StatisticsTable(user: user),
            const SizedBox(height: 16),
            _buildScoreChart(),
            const SizedBox(height: 16),
            _buildPyramidHeatMap(), // Add pyramid heat map
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart() {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: user.totalScore.toDouble(),
                  color: Colors.blue,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: user.totalMisses.toDouble(),
                  color: Colors.red,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: user.cupsHit
                      .reduce((a, b) => a + b)
                      .toDouble(), // Assuming cupsHit is a list of integers
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPyramidHeatMap() {
    List<int> cupCounts = _countCupsHit(); // Get the counts for the heat map

    return Container(
      height: 300,
      child: Column(
          children: List.generate(cupCounts.length, (index) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(index + 1, (j) {
            return Container(
              width: 30, // Adjust width as needed
              height: 30,
              color: _getHeatColor(
                  cupCounts[index], cupCounts), // Color based on count
              child: Center(
                child: Text(
                  '${cupCounts[index]}', // Show the count in the box
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          }),
        );
      })),
    );
  }

  List<int> _countCupsHit() {
    List<int> counts = List.filled(10, 0); // Only count cups from index 0 to 9
    for (var hit in user.cupsHit) {
      if (hit >= 0 && hit < counts.length) {
        counts[hit]++;
      }
    }
    return counts; // Returns counts of each index (0 to 9)
  }

  Color _getHeatColor(int count, List<int> cupCounts) {
    // Find the maximum count for scaling
    int maxCount = cupCounts.reduce((a, b) => a > b ? a : b);
    double normalizedValue = maxCount == 0 ? 0 : count / maxCount;

    // Determine color based on normalized value
    if (normalizedValue <= 0) return Colors.grey; // No hits
    if (normalizedValue <= 0.166) return Colors.green; // Low counts
    if (normalizedValue <= 0.333) return Colors.lightGreen; // Slightly higher
    if (normalizedValue <= 0.5) return Colors.yellow; // Medium counts
    if (normalizedValue <= 0.666) return Colors.orange; // Medium-high counts
    if (normalizedValue <= 0.833) return Colors.deepOrange; // High counts
    return Colors.red; // Very high counts
  }
}

class StatisticsTable extends StatelessWidget {
  final User user;

  const StatisticsTable({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      columns: const [
        DataColumn(
          label: Text(
            'Attribute',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Value',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      rows: [
        _buildDataRow('Total Score', '${user.totalScore}'),
        _buildDataRow('Total Misses', '${user.totalMisses}'),
        _buildDataRow('Total Airballs', '${user.totalAirballs}'),
        _buildDataRow('Cups Hit',
            '${user.cupsHit.length}'), // Adjust if cupsHit is a list
        _buildDataRow('Wins', '${user.wins}'),
        _buildDataRow('Losses', '${user.losses}'),
      ],
    );
  }

  DataRow _buildDataRow(String attribute, String value) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            attribute,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
