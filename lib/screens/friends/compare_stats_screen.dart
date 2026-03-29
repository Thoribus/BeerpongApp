import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user.dart';
import '../../theme.dart';

class ComparisonScreen extends StatelessWidget {
  final User currentUser;
  final User friend;

  const ComparisonScreen({
    super.key,
    required this.currentUser,
    required this.friend,
  });

  // ── Derived rate helpers ──────────────────────────────────────────────────

  double _winRate(User u) =>
      (u.wins + u.losses) > 0 ? u.wins / (u.wins + u.losses) * 100 : 0;

  double _hitRate(User u) =>
      u.totalThrows > 0 ? u.totalScore / u.totalThrows * 100 : 0;

  double _bounceRate(User u) =>
      u.bounceAttempts > 0
          ? u.bounceMakes / u.bounceAttempts * 100
          : 0;

  double _islandRate(User u) =>
      u.islandAttempts > 0
          ? u.islandMakes / u.islandAttempts * 100
          : 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: _buildCustomAppBar(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _buildRadarSection(context),
          const SizedBox(height: 24),
          _buildStatComparisonSection(context),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildCustomAppBar(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
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
                  child:
                      Icon(Icons.arrow_back, color: c.onBackground),
                ),
              ),
              Text(
                'Comparison',
                style: TextStyle(
                  color: c.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserInfo(context, currentUser, alignLeft: true),
              _buildUserInfo(context, friend, alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User user,
      {required bool alignLeft}) {
    final c = AppColors.of(context);
    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: c.surface2,
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
          style: TextStyle(
            color: c.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user.title.isNotEmpty)
          Text(
            user.title,
            style: TextStyle(
              fontSize: 11,
              color: c.subtle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignLeft
          ? [avatar, const SizedBox(width: 8), nameSection]
          : [nameSection, const SizedBox(width: 8), avatar],
    );
  }

  // ── Radar chart ───────────────────────────────────────────────────────────

  Widget _buildRadarSection(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'OVERVIEW',
            style: TextStyle(
              color: c.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        _card(
          context,
          child: Column(
            children: [
              SizedBox(height: 240, child: _buildRadarChart(context)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(Colors.orange, currentUser.username),
                  const SizedBox(width: 16),
                  _legendDot(Colors.blueAccent, friend.username),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    final cu = currentUser;
    final fr = friend;

    // All axes are 0–100 (percentage) for comparability
    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
        gridBorderData:
            const BorderSide(color: Colors.white12, width: 1),
        radarBorderData:
            const BorderSide(color: Colors.white24, width: 1),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle:
            const TextStyle(color: Colors.white70, fontSize: 11),
        getTitle: (index, angle) {
          const titles = [
            'Win Rate',
            'Hit Rate',
            'Bounce %',
            'Island %',
            'On Fire',
          ];
          return RadarChartTitle(text: titles[index], angle: angle);
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.orange.withValues(alpha: 0.25),
            borderColor: Colors.orange,
            entryRadius: 3,
            borderWidth: 2,
            dataEntries: [
              RadarEntry(value: _winRate(cu)),
              RadarEntry(value: _hitRate(cu)),
              RadarEntry(value: _bounceRate(cu)),
              RadarEntry(value: _islandRate(cu)),
              RadarEntry(value: cu.onFire.toDouble().clamp(0, 100)),
            ],
          ),
          RadarDataSet(
            fillColor: Colors.blueAccent.withValues(alpha: 0.25),
            borderColor: Colors.blueAccent,
            entryRadius: 3,
            borderWidth: 2,
            dataEntries: [
              RadarEntry(value: _winRate(fr)),
              RadarEntry(value: _hitRate(fr)),
              RadarEntry(value: _bounceRate(fr)),
              RadarEntry(value: _islandRate(fr)),
              RadarEntry(value: fr.onFire.toDouble().clamp(0, 100)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat comparison bars ──────────────────────────────────────────────────

  Widget _buildStatComparisonSection(BuildContext context) {
    final c = AppColors.of(context);

    final stats = [
      _StatRow(
        label: 'Win Rate',
        userValue: _winRate(currentUser),
        friendValue: _winRate(friend),
        format: (v) => '${v.toStringAsFixed(1)}%',
        higherIsBetter: true,
      ),
      _StatRow(
        label: 'Hit Rate',
        userValue: _hitRate(currentUser),
        friendValue: _hitRate(friend),
        format: (v) => '${v.toStringAsFixed(1)}%',
        higherIsBetter: true,
      ),
      _StatRow(
        label: 'Bounce %',
        userValue: _bounceRate(currentUser),
        friendValue: _bounceRate(friend),
        format: (v) => '${v.toStringAsFixed(1)}%',
        higherIsBetter: true,
      ),
      _StatRow(
        label: 'Island %',
        userValue: _islandRate(currentUser),
        friendValue: _islandRate(friend),
        format: (v) => '${v.toStringAsFixed(1)}%',
        higherIsBetter: true,
      ),
      _StatRow(
        label: 'Total Wins',
        userValue: currentUser.wins.toDouble(),
        friendValue: friend.wins.toDouble(),
        format: (v) => v.toInt().toString(),
        higherIsBetter: true,
      ),
      _StatRow(
        label: 'On Fire',
        userValue: currentUser.onFire.toDouble(),
        friendValue: friend.onFire.toDouble(),
        format: (v) => v.toInt().toString(),
        higherIsBetter: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'STAT COMPARISON',
            style: TextStyle(
              color: c.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        _card(
          context,
          child: Column(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  const Divider(color: Colors.white10, height: 20),
                _buildStatRow(context, stats[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, _StatRow stat) {
    final c = AppColors.of(context);
    final maxVal = [stat.userValue, stat.friendValue]
        .reduce((a, b) => a > b ? a : b);
    final userWins = stat.higherIsBetter
        ? stat.userValue >= stat.friendValue
        : stat.userValue <= stat.friendValue;
    final tied = stat.userValue == stat.friendValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.label,
              style: TextStyle(
                  color: c.subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4),
            ),
            if (!tied)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: userWins
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  userWins ? currentUser.username : friend.username,
                  style: TextStyle(
                    color:
                        userWins ? Colors.orange : Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        _duelBar(
          context,
          leftValue: stat.userValue,
          rightValue: stat.friendValue,
          maxValue: maxVal,
          leftLabel: stat.format(stat.userValue),
          rightLabel: stat.format(stat.friendValue),
        ),
      ],
    );
  }

  Widget _duelBar(
    BuildContext context, {
    required double leftValue,
    required double rightValue,
    required double maxValue,
    required String leftLabel,
    required String rightLabel,
  }) {
    final c = AppColors.of(context);
    final max = maxValue == 0 ? 1.0 : maxValue;
    final leftFrac = (leftValue / max).clamp(0.0, 1.0);
    final rightFrac = (rightValue / max).clamp(0.0, 1.0);

    return Row(
      children: [
        // User value label
        SizedBox(
          width: 44,
          child: Text(
            leftLabel,
            style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        // Left bar (user) — grows rightward from center
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 12,
                  width: constraints.maxWidth * leftFrac,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
        // Center divider
        Container(
            width: 2,
            height: 20,
            color: c.subtle,
            margin: const EdgeInsets.symmetric(horizontal: 4)),
        // Right bar (friend) — grows leftward from center
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              children: [
                Container(
                  height: 12,
                  width: constraints.maxWidth * rightFrac,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(width: 6),
        // Friend value label
        SizedBox(
          width: 44,
          child: Text(
            rightLabel,
            style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _card(BuildContext context, {required Widget child}) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

// ── Value object ──────────────────────────────────────────────────────────────

class _StatRow {
  final String label;
  final double userValue;
  final double friendValue;
  final String Function(double) format;
  final bool higherIsBetter;

  const _StatRow({
    required this.label,
    required this.userValue,
    required this.friendValue,
    required this.format,
    required this.higherIsBetter,
  });
}
