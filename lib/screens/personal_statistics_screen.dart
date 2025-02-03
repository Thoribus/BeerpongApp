import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildStatisticsTiles(user), // 2x2 rectangle brackets layout
            const SizedBox(height: 24),
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
            _buildSectionTitle("Game History"),
            _buildCard(
              child: FutureBuilder<List<UserStatsInGame>>(
                future: FirestoreService().retrieveUserStatsWithDate(user),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final userStats = snapshot.data ?? [];
                  return _buildGameHistoryChart(userStats);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHistoryChart(List<UserStatsInGame> userStats) {
    String selectedXAxis = 'Date'; // Default x-axis option
    final List<String> xAxisOptions = [
      'Date',
      'Game Number'
    ]; // Dropdown options

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brackets with Data and Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Bracket: "Data"
                _buildBracket(
                  content: const Text(
                    'Data',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                // Right Bracket: Dropdown Menu
                _buildBracket(
                  content: DropdownButton<String>(
                    value: selectedXAxis,
                    dropdownColor: Colors.grey[800],
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    underline: Container(height: 0), // Remove underline
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedXAxis = newValue!;
                      });
                    },
                    items: xAxisOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Line Chart
            _buildLineChart(userStats, selectedXAxis),
          ],
        );
      },
    );
  }

  /// Builds a bracket-style container with custom content
  Widget _buildBracket({required Widget content}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: content,
    );
  }

  /// Builds the line chart with the selected x-axis type
  Widget _buildLineChart(List<UserStatsInGame> userStats, String xAxis) {
    if (userStats.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final gradientColors = [
      const Color(0xff23b6e6),
      const Color(0xff02d39a),
    ];

    List<FlSpot> spots = userStats.asMap().entries.map((entry) {
      double xValue = xAxis == 'Date'
          ? entry.key.toDouble()
          : entry.value.date.millisecondsSinceEpoch.toDouble();
      return FlSpot(xValue, entry.value.player.score.toDouble());
    }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: userStats.length.toDouble() - 1,
          minY: 0,
          maxY: userStats
                  .map((e) => e.player.score)
                  .reduce((a, b) => a > b ? a : b) +
              10,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (xAxis == 'Date') {
                    int index = value.toInt();
                    if (index < 0 || index >= userStats.length)
                      return const Text('');
                    return Text(
                      userStats[index]
                          .date
                          .toLocal()
                          .toIso8601String()
                          .split('T')[0],
                      style: const TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    );
                  } else {
                    return Text(
                      '${value.toInt()}',
                      style: const TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    );
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                        color: Color(0xff67727d),
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 10,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(color: Color(0xff37434d), strokeWidth: 1);
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              barWidth: 6,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTiles(User user) {
    final stats = [
      {'icon': Icons.score, 'title': 'Total Score', 'value': user.totalScore},
      {
        'icon': Icons.air,
        'title': 'Total Airballs',
        'value': user.totalAirballs
      },
      {
        'icon': Icons.sports_bar,
        'title': 'Cups Hit',
        'value': user.cupsHit.length
      },
      {'icon': Icons.emoji_events, 'title': 'Wins', 'value': user.wins},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5, // Half the height
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Icon with circle background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Value and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stat['value']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stat['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildPyramidHeatMap() {
    List<int> cupCounts = _countCupsHit();

    // Define the rows of the pyramid
    List<List<int>> pyramidRows = [
      [0, 1, 2, 3],
      [4, 5, 6],
      [7, 8],
      [9]
    ];

    return SizedBox(
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

    double normalizedValue = (maxCount == minCount)
        ? 0.0
        : (count - minCount) / (maxCount - minCount);

    if (normalizedValue <= 0) return Colors.amber[100]!;
    if (normalizedValue <= 0.2) return Colors.amber[200]!;
    if (normalizedValue <= 0.4) return Colors.amber[400]!;
    if (normalizedValue <= 0.6) return Colors.amber[600]!;
    if (normalizedValue <= 0.8) return Colors.amber[800]!;
    return Colors.amber[900]!;
  }
}

class StatisticsTable extends StatelessWidget {
  final User user;

  const StatisticsTable({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true, // Prevents infinite height issue
      physics: NeverScrollableScrollPhysics(), // Disables internal scrolling
      children: [
        _buildStatRow(
            context, 'Total Score', user.totalScore.toInt(), Icons.score, 0.02),
        _buildStatRow(
            context, 'Total Misses', user.totalMisses, Icons.close, -1.5),
        _buildStatRow(
            context, 'Total Airballs', user.totalAirballs, Icons.air, 0.5),
        _buildStatRow(
            context, 'Cups Hit', user.cupsHit.length, Icons.sports_bar, -0.3),
        _buildStatRow(context, 'Wins', user.wins, Icons.emoji_events, 1.2),
        _buildStatRow(context, 'Losses', user.losses, Icons.cancel, -0.8),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String attribute, int value,
      IconData icon, double change) {
    List<FlSpot> trendData = _generatePlaceholderData(value);
    bool isPositive = change >= 0;
    Color trendColor = isPositive ? Colors.green : Colors.red;

    return ListTile(
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(attribute,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Icon(icon, color: Colors.amber, size: 20),
        ],
      ),
      title: SizedBox(
        height: 30,
        width: 80,
        child: LineChart(
          LineChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: trendData,
                isCurved: true,
                color: trendColor,
                barWidth: 2,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value.toInt().toString(),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            '${change.toStringAsFixed(2)}%',
            style: TextStyle(
                color: trendColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
      onTap: () => _showDetailChart(context, attribute, trendData, trendColor),
    );
  }

  void _showDetailChart(
      BuildContext context, String attribute, List<FlSpot> data, Color color) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(attribute, style: TextStyle(color: Colors.white)),
          content: SizedBox(
            height: 250,
            width: 300,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: true),
                gridData: FlGridData(
                    drawVerticalLine: true, drawHorizontalLine: true),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    belowBarData:
                        BarAreaData(show: true, color: color.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<FlSpot> _generatePlaceholderData(int value) {
    return List.generate(
        10,
        (index) =>
            FlSpot(index.toDouble(), (value * (0.9 + (index % 3) * 0.05))));
  }
}
