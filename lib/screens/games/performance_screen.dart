import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';

class PerformanceScreen extends StatefulWidget {
  final User user;

  const PerformanceScreen({super.key, required this.user});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

enum _TimeFilter { all, last10, last5, last3 }

class _PerformanceScreenState extends State<PerformanceScreen> {
  late final Future<List<UserStatsInGame>> _statsFuture;
  _TimeFilter _filter = _TimeFilter.all;

  @override
  void initState() {
    super.initState();
    _statsFuture =
        FirestoreService.instance.retrieveUserStatsWithDate(widget.user);
  }

  List<UserStatsInGame> _applyFilter(List<UserStatsInGame> all) {
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return switch (_filter) {
      _TimeFilter.last10 => sorted.take(10).toList(),
      _TimeFilter.last5 => sorted.take(5).toList(),
      _TimeFilter.last3 => sorted.take(3).toList(),
      _TimeFilter.all => sorted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterChips(),
            const SizedBox(height: 8),
            FutureBuilder<List<UserStatsInGame>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final filtered = _applyFilter(snapshot.data ?? []);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle(context.loc.perfSummaryTitle),
                    _buildCard(
                      child: StatisticsTable(
                        user: widget.user,
                        userStatsList: filtered,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context.loc.perfHeatMapTitle),
                    _buildCard(child: _buildPyramidHeatMap()),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context.loc.perfRowAccuracyTitle),
                    _buildCard(child: _buildRowAccuracyChart()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _filterChip(context.loc.perfFilterAll, _TimeFilter.all),
        const SizedBox(width: 8),
        _filterChip(context.loc.perfFilterLast10, _TimeFilter.last10),
        const SizedBox(width: 8),
        _filterChip(context.loc.perfFilterLast5, _TimeFilter.last5),
        const SizedBox(width: 8),
        _filterChip(context.loc.perfFilterLast3, _TimeFilter.last3),
      ],
    );
  }

  Widget _filterChip(String label, _TimeFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: c.onBackground,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final c = AppColors.of(context);
    return Card(
      color: c.surface2,
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
    for (var hit in widget.user.cupsHit) {
      if (hit >= 0 && hit < counts.length) {
        counts[hit]++;
      }
    }
    return counts;
  }

  Widget _buildRowAccuracyChart() {
    final c = AppColors.of(context);
    final counts = _countCupsHit();
    final total = counts.reduce((a, b) => a + b);

    // Row groupings: front [0-3], mid [4-6], back [7-8], apex [9]
    final rowHits = [
      counts[0] + counts[1] + counts[2] + counts[3],
      counts[4] + counts[5] + counts[6],
      counts[7] + counts[8],
      counts[9],
    ];
    final rowLabels = [context.loc.perfRowFront, context.loc.perfRowMid, context.loc.perfRowBack, context.loc.perfRowApex];

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(context.loc.perfNoData,
            style: TextStyle(color: c.subtle, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(4, (i) {
        final pct = rowHits[i] / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  rowLabels[i],
                  style: TextStyle(color: c.subtle, fontSize: 11),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: c.onBackground,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
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
  final List<UserStatsInGame> userStatsList; // All the user's games

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
    final bounceRateSpots = _buildTrend((p) => p.bounceAttempts == 0
        ? 0.0
        : (p.bounceMakes / p.bounceAttempts) * 100.0);
    final islandConversionSpots = _buildTrend((p) => p.islandAttempts == 0
        ? 0.0
        : (p.islandMakes / p.islandAttempts) * 100.0);
    final defendedSpots = _buildTrend((p) => p.defended.toDouble());
    final onFireSpots = _buildTrend((p) => p.onFire.toDouble());
    final heatingUpSpots = _buildTrend((p) => p.heatingUp.toDouble());

    // 2) Compute slope-based "change" for each measure
    final scoreChange = _computeSlopeAsPercentChange(scoreSpots);
    final missesChange = _computeSlopeAsPercentChange(missesSpots);
    final airballsChange = _computeSlopeAsPercentChange(airballsSpots);
    final cupsHitChange = _computeSlopeAsPercentChange(cupsHitSpots);
    final hitRateChange = _computeSlopeAsPercentChange(hitRateSpots);
    final winRateChange = _computeSlopeAsPercentChange(winRateSpots);
    final bounceRateChange = _computeSlopeAsPercentChange(bounceRateSpots);
    final islandConversionChange =
        _computeSlopeAsPercentChange(islandConversionSpots);
    final defendedChange = _computeSlopeAsPercentChange(defendedSpots);
    final onFireChange = _computeSlopeAsPercentChange(onFireSpots);
    final heatingUpChange = _computeSlopeAsPercentChange(heatingUpSpots);

    final bounceRateLifetime = user.bounceAttempts > 0
        ? (user.bounceMakes / user.bounceAttempts * 100).round()
        : 0;
    final islandConversionLifetime = user.islandAttempts > 0
        ? (user.islandMakes / user.islandAttempts * 100).round()
        : 0;

    final dates =
        _sortByDate(userStatsList).map((e) => e.date).toList();

    // 3) Build the rows
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatRow(
          context, context.loc.statTotalScore, user.totalScore.toInt(),
          Icons.score, scoreChange, scoreSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statTotalMisses, user.totalMisses,
          Icons.close, missesChange, missesSpots, dates,
          lessIsBetter: true,
        ),
        _buildStatRow(
          context, context.loc.statTotalAirballs, user.totalAirballs,
          Icons.air, airballsChange, airballsSpots, dates,
          lessIsBetter: true,
        ),
        _buildStatRow(
          context, context.loc.statCupsHit, user.cupsHit.length,
          Icons.sports_bar, cupsHitChange, cupsHitSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statHitRate, _hitRateUserLevel(user).round(),
          Icons.auto_fix_high, hitRateChange, hitRateSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statWinRate, _winRateUserLevel(user).round(),
          Icons.emoji_events, winRateChange, winRateSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statBounceRate, bounceRateLifetime,
          Icons.sports_tennis_rounded, bounceRateChange, bounceRateSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statIslandConv, islandConversionLifetime,
          Icons.workspaces_outlined, islandConversionChange,
          islandConversionSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statDefended, user.defended,
          Icons.shield_outlined, defendedChange, defendedSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statOnFire, user.onFire,
          Icons.local_fire_department, onFireChange, onFireSpots, dates,
        ),
        _buildStatRow(
          context, context.loc.statHeatingUp, user.totalHeatingUp,
          Icons.thermostat, heatingUpChange, heatingUpSpots, dates,
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
    List<DateTime> dates, {
    bool lessIsBetter = false,
  }) {
    final isPositive =
        lessIsBetter ? changePercent < 0 : changePercent >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;

    final c = AppColors.of(context);
    return ListTile(
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attribute,
            style: TextStyle(
                color: c.onBackground, fontWeight: FontWeight.bold),
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
            style: TextStyle(
              color: c.onBackground,
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
      onTap: () => _showDetailChart(context, attribute, rawData, dates),
    );
  }

  /// On tap, show a bigger chart with BOTH raw data and the regression line
  void _showDetailChart(
    BuildContext context,
    String attribute,
    List<FlSpot> rawData,
    List<DateTime> dates,
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
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: dates.isNotEmpty,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final d = dates[idx];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
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
