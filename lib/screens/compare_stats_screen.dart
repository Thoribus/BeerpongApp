import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/user.dart';

class ComparisonScreen extends StatefulWidget {
  final User currentUser;
  final User friend;

  const ComparisonScreen({
    super.key,
    required this.currentUser,
    required this.friend,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String selectedPeriod = 'ALL';

  final List<String> timeFilters = [
    'ALL',
    'Last 7 Days',
    'Last 30 Days',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: _buildCustomAppBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8), // some spacing below app bar
          _buildAvatarsAndRadar(),
          const SizedBox(height: 32),
          _buildBarChartSection(),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          // Top Row: User info - VS - Friend info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserInfo(widget.currentUser, alignLeft: true),
              _buildUserInfo(widget.friend, alignLeft: false),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Row: Time filter buttons
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: timeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final filter = timeFilters[index];
                final isSelected = selectedPeriod == filter;

                return GestureDetector(
                  onTap: () => setState(() => selectedPeriod = filter),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        filter.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(User user, {required bool alignLeft}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!alignLeft) ...[
          // For friend (right side), avatar first on right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: SvgPicture.asset(
                'assets/avatars/${user.avatarKey}.svg',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ] else ...[
          // For current user (left side), avatar first on left
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: ClipOval(
              child: SvgPicture.asset(
                'assets/avatars/${user.avatarKey}.svg',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarsAndRadar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUserAvatar(widget.currentUser),
            const Text(
              'VS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            _buildUserAvatar(widget.friend),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _buildRadarChart(),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey[300],
          child: ClipOval(
            child: SvgPicture.asset(
              'assets/avatars/${user.avatarKey}.svg',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  Widget _buildRadarChart() {
    final stats = [
      {
        'title': 'Total Score',
        'current': widget.currentUser.totalScore.toDouble(),
        'friend': widget.friend.totalScore.toDouble(),
      },
      {
        'title': 'Total Throws',
        'current': widget.currentUser.totalThrows.toDouble(),
        'friend': widget.friend.totalThrows.toDouble(),
      },
      {
        'title': 'Wins',
        'current': widget.currentUser.wins.toDouble(),
        'friend': widget.friend.wins.toDouble(),
      },
      {
        'title': 'Losses',
        'current': widget.currentUser.losses.toDouble(),
        'friend': widget.friend.losses.toDouble(),
      },
      {
        'title': 'Misses',
        'current': widget.currentUser.totalMisses.toDouble(),
        'friend': widget.friend.totalMisses.toDouble(),
      },
    ];

    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        radarShape: RadarShape.polygon,
        tickCount: 5,
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 12),
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: stats[index]['title'] as String,
            angle: angle,
          );
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.orange.withOpacity(0.3),
            borderColor: Colors.orange,
            entryRadius: 3,
            dataEntries: stats
                .map((stat) => RadarEntry(value: stat['current'] as double))
                .toList(),
          ),
          RadarDataSet(
            fillColor: Colors.grey.withOpacity(0.3),
            borderColor: Colors.grey,
            entryRadius: 3,
            dataEntries: stats
                .map((stat) => RadarEntry(value: stat['friend'] as double))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    final List<String> labels = ['Time', 'Score', 'Volume'];
    final List<double> userValues = [
      7.0,
      widget.currentUser.totalScore.toDouble(),
      81644
    ];
    final List<double> friendValues = [
      22.0,
      widget.friend.totalScore.toDouble(),
      130436
    ];

    final maxY = [userValues, friendValues]
        .expand((list) => list)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparison',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.4,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + maxY * 0.1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY / 4,
                    reservedSize: 28,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      if (value < 0 || value >= labels.length)
                        return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          labels[value.toInt()],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              barGroups: List.generate(labels.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: userValues[i],
                      color: Colors.orange,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: friendValues[i],
                      color: Colors.grey,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
