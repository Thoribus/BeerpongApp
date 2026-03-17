import 'dart:math' as math;

import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PersonalStatisticsScreen extends StatelessWidget {
  final User user;
  final List<GameStatistics> games;

  const PersonalStatisticsScreen({
    super.key,
    required this.user,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 14),
            _buildRecentFormStrip(context),
            const SizedBox(height: 14),
            _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
    final totalGames = user.wins + user.losses;
    final winPct = totalGames > 0 ? user.wins / totalGames : 0.0;
    final hitPct = user.totalThrows > 0
        ? (user.totalScore / user.totalThrows * 100)
        : 0.0;
    final avatarPath =
        user.avatarKey.isNotEmpty ? user.mapAvatarKeyToAsset() : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFF5C2A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildWinRateRing(winPct, avatarPath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _chip('${user.wins}W', Colors.green.shade800),
                    _chip('${user.losses}L', Colors.red.shade800),
                    _chip(
                      '${(winPct * 100).toStringAsFixed(0)}% WR',
                      Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hit rate: ${hitPct.toStringAsFixed(1)}%',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildWinRateRing(double progress, String? avatarPath) => SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(72, 72),
              painter: _RingPainter(progress: progress),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: avatarPath != null && avatarPath.isNotEmpty
                  ? ClipOval(
                      child: SvgPicture.asset(
                        avatarPath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 28, color: Colors.white),
            ),
          ],
        ),
      );

  // ── Recent form strip ────────────────────────────────────────────────────

  Widget _buildRecentFormStrip(BuildContext context) {
    final c = AppColors.of(context);
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(8).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Form',
          style: TextStyle(
            color: c.subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: recent.map((g) {
            final won = g.winningTeam == 'Team 1'
                ? g.team1Players.any((p) => p.name == user.username)
                : g.team2Players.any((p) => p.name == user.username);
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: won
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                boxShadow: [
                  BoxShadow(
                    color: (won ? Colors.green : Colors.red)
                        .withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  won ? 'W' : 'L',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 8-tile stat grid ─────────────────────────────────────────────────────

  Widget _buildStatsGrid(BuildContext context) {
    final totalGames = user.wins + user.losses;
    final winPct =
        totalGames > 0 ? (user.wins / totalGames * 100) : 0.0;
    final hitPct = user.totalThrows > 0
        ? (user.totalScore / user.totalThrows * 100)
        : 0.0;
    final bouncePct = user.totalBounceAttempts > 0
        ? (user.totalBounceMakes / user.totalBounceAttempts * 100)
        : 0.0;

    final tiles = [
      _TileDef(Icons.emoji_events, 'Wins', '${user.wins}', Colors.amber),
      _TileDef(Icons.close_rounded, 'Losses', '${user.losses}', Colors.redAccent),
      _TileDef(
        Icons.percent,
        'Win Rate',
        '${winPct.toStringAsFixed(0)}%',
        Colors.green,
      ),
      _TileDef(
        Icons.auto_fix_high,
        'Hit Rate',
        '${hitPct.toStringAsFixed(0)}%',
        Colors.blue,
      ),
      _TileDef(
        Icons.sports_bar,
        'Cups Hit',
        '${user.cupsHit.length}',
        Colors.orange,
      ),
      _TileDef(
        Icons.local_fire_department,
        'On Fire',
        '${user.onFire}',
        Colors.deepOrange,
      ),
      _TileDef(
        Icons.sports_tennis_rounded,
        'Bounce%',
        '${bouncePct.toStringAsFixed(0)}%',
        Colors.purple,
      ),
      _TileDef(
        Icons.workspaces_outlined,
        'Islands',
        '${user.totalIslandMakes}',
        Colors.teal,
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => _buildTile(context, tiles[i]),
    );
  }

  Widget _buildTile(BuildContext context, _TileDef tile) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tile.icon, color: tile.color, size: 22),
          const SizedBox(height: 4),
          Text(
            tile.value,
            style: TextStyle(
              color: c.onBackground,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              tile.label,
              style: TextStyle(color: c.subtle, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting types ──────────────────────────────────────────────────────

class _TileDef {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TileDef(this.icon, this.label, this.value, this.color);
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0–1.0

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = Colors.white24;
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = Colors.amber;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
