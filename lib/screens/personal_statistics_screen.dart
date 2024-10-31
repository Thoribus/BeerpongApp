import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beerpongapp/models/user.dart';

// Class representing a cup in the game
class Cup {
  final int index; // The index of the cup
  bool isVisible; // Visibility status of the cup
  GlobalKey key; // Key to identify the cup widget
  Color color;

  // Constructor initializing the cup's index and setting it as visible by default
  Cup({required this.index, this.color = Colors.red, isVisible, key})
      : isVisible = isVisible ?? true,
        key = key ?? GlobalKey();

  // Method to create a widget representing the cup
  Widget widget(int hitCount) {
    return Visibility(
      visible: isVisible, // Determines whether the cup is visible
      maintainSize:
          true, // Maintains the size of the widget even when it's not visible
      maintainAnimation:
          true, // Maintains the animation state when visibility changes
      maintainState:
          true, // Maintains the state of the widget when visibility changes
      child: Container(
        key: key, // Key to identify the cup widget
        margin: const EdgeInsets.all(8.0), // Margin around the cup
        width: 60.0, // Width of the cup
        height: 60.0, // Height of the cup
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          color: color, // Color of the cup
          shape: BoxShape.circle, // Shape of the cup
        ),
        child: Center(
          child: Text(
            '$hitCount', // Display the count in the cup
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class PersonalStatisticsScreen extends StatelessWidget {
  final User user;

  const PersonalStatisticsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("Statistics"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildSectionTitle("Performance Summary"),
            _buildCard(
              child: StatisticsTable(user: user),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle("Cups Hit Heat Map"),
            _buildCard(
              child: _buildPyramidHeatMap(),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Score Overview"),
            _buildCard(
              child: _buildScoreChart(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget to build the section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildScoreChart() {
    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.grey[800],
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}',
                  style: TextStyle(color: Colors.amber[200]),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Score',
                          style: TextStyle(color: Colors.amber[200]));
                    case 1:
                      return Text('Misses',
                          style: TextStyle(color: Colors.amber[200]));
                    case 2:
                      return Text('Cups',
                          style: TextStyle(color: Colors.amber[200]));
                    default:
                      return Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: user.totalScore.toDouble(),
                  color: Colors.amber,
                  width: 18,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: user.totalMisses.toDouble(),
                  color: Colors.redAccent,
                  width: 18,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: user.cupsHit.reduce((a, b) => a + b).toDouble(),
                  color: Colors.greenAccent,
                  width: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPyramidHeatMap() {
    List<int> cupCounts = _countCupsHit();

    // Define the rows of the pyramid
    List<List<int>> pyramidRows = [
      [0, 1, 2, 3],
      [4, 5, 6],
      [7, 8],
      [9]
    ];

    return Container(
      height: 300,
      child: Column(
        children: pyramidRows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((index) {
              Cup cup = Cup(
                index: index,
                color: _getHeatColor(cupCounts[index], cupCounts),
              );
              return cup.widget(cupCounts[index]);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  List<int> _countCupsHit() {
    List<int> counts = List.filled(10, 0);
    for (var hit in user.cupsHit) {
      if (hit >= 0 && hit < counts.length) {
        counts[hit]++;
      }
    }
    return counts;
  }

  Color _getHeatColor(int count, List<int> cupCounts) {
    int minCount = cupCounts.reduce((a, b) => a < b ? a : b);
    int maxCount = cupCounts.reduce((a, b) => a > b ? a : b);

    // Normalize the count to a value between 0 and 1
    double normalizedValue = (maxCount == minCount)
        ? 0.0
        : (count - minCount) / (maxCount - minCount);

    // Determine the color based on the normalized value
    if (normalizedValue <= 0)
      return Colors.amber[100]!; // Lightest amber for no hits
    if (normalizedValue <= 0.2) return Colors.amber[200]!;
    if (normalizedValue <= 0.4) return Colors.amber[400]!;
    if (normalizedValue <= 0.6) return Colors.amber[600]!;
    if (normalizedValue <= 0.8) return Colors.amber[800]!;
    return Colors.amber[900]!; // Darkest amber for most hits
  }
}

class StatisticsTable extends StatelessWidget {
  final User user;

  const StatisticsTable({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 0, // Remove header row for minimalism
        dividerThickness: 0, // Remove horizontal dividers
        columns: const [
          DataColumn(
              label: SizedBox
                  .shrink()), // Empty label for icon and attribute column
          DataColumn(label: SizedBox.shrink()), // Empty label for value column
        ],
        rows: [
          _buildDataRow(Icons.score, 'Total Score', '${user.totalScore}'),
          _buildDataRow(Icons.close, 'Total Misses', '${user.totalMisses}'),
          _buildDataRow(Icons.air, 'Total Airballs', '${user.totalAirballs}'),
          _buildDataRow(Icons.sports_bar, 'Cups Hit', '${user.cupsHit.length}'),
          _buildDataRow(Icons.emoji_events, 'Wins', '${user.wins}'),
          _buildDataRow(Icons.cancel, 'Losses', '${user.losses}'),
        ],
      ),
    );
  }

  DataRow _buildDataRow(IconData icon, String attribute, String value) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attribute,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
