import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user.dart';

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
  int selectedIndex = 0;

  final List<Map<String, String>> timeFilterItems = [
    {'day': 'TIME', 'num': 'ALL'},
    {'day': 'WEEK', 'num': '1'},
    {'day': 'MON', 'num': '1'},
    {'day': 'YEAR', 'num': '1'},
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
          const SizedBox(height: 8),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 6),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const Center(
                  child: Text(
                    'Comparison',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // SMALLER SPACE

            // User info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUserInfo(widget.currentUser, alignLeft: true),
                _buildUserInfo(widget.friend, alignLeft: false),
              ],
            ),

            const SizedBox(height: 8), // SMALLER SPACE

            // Time filter stays inside, centered
            Center(child: _buildTimeFilterBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterBar() {
    return Container(
      height: 48,
      width: 280, // Fixed width to avoid overflow
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: timeFilterItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['num']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    item['day']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatarsAndRadar() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: _buildRadarChart(),
        ),
      ],
    );
  }

  Widget _buildUserInfo(User user, {required bool alignLeft}) {
    final avatar = CircleAvatar(
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
    );

    final nameSection = Column(
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          user.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '@${user.username}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Row(
      children: alignLeft
          ? [avatar, const SizedBox(width: 8), nameSection]
          : [nameSection, const SizedBox(width: 8), avatar],
    );
  }

  Widget _buildRadarChart() {
    final stats = [
      {
        'title': 'Total Score',
        'current': widget.currentUser.totalScore.toDouble(),
        'friend': widget.friend.totalScore.toDouble()
      },
      {
        'title': 'Total Throws',
        'current': widget.currentUser.totalThrows.toDouble(),
        'friend': widget.friend.totalThrows.toDouble()
      },
      {
        'title': 'Wins',
        'current': widget.currentUser.wins.toDouble(),
        'friend': widget.friend.wins.toDouble()
      },
      {
        'title': 'Losses',
        'current': widget.currentUser.losses.toDouble(),
        'friend': widget.friend.losses.toDouble()
      },
      {
        'title': 'Misses',
        'current': widget.currentUser.totalMisses.toDouble(),
        'friend': widget.friend.totalMisses.toDouble()
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
              text: stats[index]['title'] as String, angle: angle);
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.orange.withValues(alpha: 0.3),
            borderColor: Colors.orange,
            entryRadius: 3,
            dataEntries: stats
                .map((stat) => RadarEntry(value: stat['current'] as double))
                .toList(),
          ),
          RadarDataSet(
            fillColor: Colors.grey.withValues(alpha: 0.3),
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
    final radarStats = [
      {
        'title': 'Total Score',
        'user': widget.currentUser.totalScore.toDouble(),
        'friend': widget.friend.totalScore.toDouble(),
      },
      {
        'title': 'Total Throws',
        'user': widget.currentUser.totalThrows.toDouble(),
        'friend': widget.friend.totalThrows.toDouble(),
      },
      {
        'title': 'Wins',
        'user': widget.currentUser.wins.toDouble(),
        'friend': widget.friend.wins.toDouble(),
      },
      {
        'title': 'Losses',
        'user': widget.currentUser.losses.toDouble(),
        'friend': widget.friend.losses.toDouble(),
      },
      {
        'title': 'Misses',
        'user': widget.currentUser.totalMisses.toDouble(),
        'friend': widget.friend.totalMisses.toDouble(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparison',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ...radarStats.map((stat) {
          final double userValue = stat['user'] as double;
          final double friendValue = stat['friend'] as double;
          final double maxValue =
              userValue > friendValue ? userValue : friendValue;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                stat['title'] as String,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // User Bar
              _buildHorizontalStatBar(
                value: userValue,
                maxValue: maxValue,
                color: Colors.orange,
              ),

              // Friend Bar
              _buildHorizontalStatBar(
                value: friendValue,
                maxValue: maxValue,
                color: Colors.grey,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHorizontalStatBar({
    required double value,
    required double maxValue,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth =
              (value / (maxValue == 0 ? 1 : maxValue)) * constraints.maxWidth;

          return Stack(
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 20,
                width: barWidth,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
