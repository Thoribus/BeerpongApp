import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';

class PerformanceScreen extends StatelessWidget {
  final User user;

  const PerformanceScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Load userStatsInGame from Firestore
            FutureBuilder<List<UserStatsInGame>>(
              future: FirestoreService().retrieveUserStatsWithDate(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final userStatsList = snapshot.data ?? [];

                // 2) Now we have userStatsList for line charts etc.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // "Performance Summary": use a custom card
                    _buildSectionTitle("Performance Summary"),
                    _buildCard(
                      child: StatisticsTable(
                        user: user,
                        userStatsList: userStatsList, // pass it here
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Heat Map
                    _buildSectionTitle("Cups Hit Heat Map"),
                    _buildCard(
                      child: _buildPyramidHeatMap(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      color: Colors.grey[200],
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

    return Column(
      children: pyramidRows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((index) {
            Cup cup = Cup(
              index: index,
              color: _getHeatColor(cupCounts[index], cupCounts),
            );
            return cup.widget(onTap: () => {}, hitCount: cupCounts[index]);
          }).toList(),
        );
      }).toList(),
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

/// The table widget
class StatisticsTable extends StatelessWidget {
  final User user;
  final List<UserStatsInGame> userStatsList; // All the user’s games

  const StatisticsTable({
    super.key,
    required this.user,
    required this.userStatsList,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Build spots for each measure
    final scoreSpots = _buildTrend((p) => p.score.toDouble());
    final missesSpots = _buildTrend((p) => p.misses.toDouble());
    final airballsSpots = _buildTrend((p) => p.airballs.toDouble());
    final cupsHitSpots = _buildTrend((p) => p.cupsHit.length.toDouble());
    final hitRateSpots =
        _buildTrend((p) => p.throws == 0 ? 0.0 : (p.score / p.throws) * 100.0);
    final winRateSpots = _buildTrendWinRate();

    // 2) Compute slope-based "change" for each measure
    final scoreChange = _computeSlopeAsPercentChange(scoreSpots);
    final missesChange = _computeSlopeAsPercentChange(missesSpots);
    final airballsChange = _computeSlopeAsPercentChange(airballsSpots);
    final cupsHitChange = _computeSlopeAsPercentChange(cupsHitSpots);
    final hitRateChange = _computeSlopeAsPercentChange(hitRateSpots);
    final winRateChange = _computeSlopeAsPercentChange(winRateSpots);

    // 3) Build the rows
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatRow(
          context,
          'Total Score',
          user.totalScore.toInt(),
          Icons.score,
          scoreChange,
          scoreSpots,
        ),
        _buildStatRow(
          context,
          'Total Misses',
          user.totalMisses,
          Icons.close,
          missesChange,
          missesSpots,
        ),
        _buildStatRow(
          context,
          'Total Airballs',
          user.totalAirballs,
          Icons.air,
          airballsChange,
          airballsSpots,
        ),
        _buildStatRow(
          context,
          'Cups Hit',
          user.cupsHit.length,
          Icons.sports_bar,
          cupsHitChange,
          cupsHitSpots,
        ),
        _buildStatRow(
          context,
          'Hit Rate',
          _hitRateUserLevel(user).round(),
          Icons.auto_fix_high,
          hitRateChange,
          hitRateSpots,
        ),
        _buildStatRow(
          context,
          'Win Rate',
          _winRateUserLevel(user).round(),
          Icons.emoji_events,
          winRateChange,
          winRateSpots,
        ),
      ],
    );
  }

  //region -- Building Each Stat Row --

  Widget _buildStatRow(
    BuildContext context,
    String attribute,
    int value,
    IconData icon,
    double changePercent,
    List<FlSpot> rawData,
  ) {
    final isPositive =
        _lessIsBetter(attribute) ? changePercent < 0 : changePercent >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return ListTile(
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attribute,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Icon(icon, color: Colors.orange, size: 20),
        ],
      ),
      // The small sparkline (just raw data)
      title: SizedBox(
        height: 30,
        width: 80,
        child: LineChart(
          LineChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: rawData,
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
            '$value',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: () => _showDetailChart(context, attribute, rawData),
    );
  }

  bool _lessIsBetter(String attribute) {
    // If the attribute name is "Total Misses" or "Total Airballs", returning true
    // means we’ll invert the color logic (negative slope => green).
    return attribute == "Total Misses" || attribute == "Total Airballs";
  }

  /// On tap, show a bigger chart with BOTH raw data and the regression line
  void _showDetailChart(
    BuildContext context,
    String attribute,
    List<FlSpot> rawData,
  ) {
    final line = _createRegressionLine(rawData);
    const slopeColor = Colors.orange;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(attribute, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            height: 300,
            width: 400,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: true),
                gridData: const FlGridData(
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  // Raw data line
                  LineChartBarData(
                    spots: rawData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Regression line
                  LineChartBarData(
                    spots: line,
                    isCurved: false,
                    color: slopeColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  //endregion

  // --- Trend Builders using Linear Regression ---
  List<FlSpot> _buildTrend(num Function(Player) extractor) {
    final sorted = _sortByDate(userStatsList);
    return List.generate(sorted.length, (i) {
      final value = extractor(sorted[i].player);
      return FlSpot(i.toDouble(), value.toDouble());
    });
  }

  List<FlSpot> _buildTrendWinRate() {
    final sorted = _sortByDate(userStatsList);
    int cumulativeWins = 0;
    return List.generate(sorted.length, (i) {
      if (sorted[i].player.isWinner) cumulativeWins++;
      double winRate = (cumulativeWins / (i + 1)) * 100.0;
      return FlSpot(i.toDouble(), winRate);
    });
  }

  List<UserStatsInGame> _sortByDate(List<UserStatsInGame> list) {
    final copy = [...list];
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }

  /// Compute the slope from linear regression and return the percent change relative to the average.
  double _computeSlopeAsPercentChange(List<FlSpot> spots) {
    if (spots.length < 2) return 0.0;
    final regression = _computeLinearRegression(spots);
    final slope = regression.first;
    final avg = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    if (avg.abs() < 1e-9) return 0.0;
    return (slope / avg) * 100.0;
  }

  /// Compute a simple linear regression on the given spots.
  Pair<double, double> _computeLinearRegression(List<FlSpot> spots) {
    final n = spots.length;
    if (n < 2) {
      final avgY = n == 1 ? spots[0].y : 0.0;
      return Pair(0.0, avgY);
    }
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final s in spots) {
      sumX += s.x;
      sumY += s.y;
      sumXY += s.x * s.y;
      sumX2 += s.x * s.x;
    }
    final numerator = n * sumXY - sumX * sumY;
    final denominator = n * sumX2 - sumX * sumX;
    if (denominator.abs() < 1e-9) return Pair(0.0, sumY / n);
    final slope = numerator / denominator;
    final intercept = (sumY - slope * sumX) / n;
    return Pair(slope, intercept);
  }

  /// Create two points representing the regression line (from minX to maxX).
  List<FlSpot> _createRegressionLine(List<FlSpot> raw) {
    if (raw.length < 2) return [];
    final regression = _computeLinearRegression(raw);
    final slope = regression.first;
    final intercept = regression.second;
    final minX = raw.first.x;
    final maxX = raw.last.x;
    return [
      FlSpot(minX, slope * minX + intercept),
      FlSpot(maxX, slope * maxX + intercept),
    ];
  }

  // --- Final User-Level Computations ---
  double _winRateUserLevel(User user) {
    final totalGames = user.wins + user.losses;
    if (totalGames == 0) return 0.0;
    return (user.wins / totalGames) * 100.0;
  }

  double _hitRateUserLevel(User user) {
    if (user.totalThrows == 0) return 0.0;
    return (user.totalScore / user.totalThrows) * 100.0;
  }
}

/// Helper class for pairing two values.
class Pair<A, B> {
  final A first;
  final B second;
  Pair(this.first, this.second);
}
