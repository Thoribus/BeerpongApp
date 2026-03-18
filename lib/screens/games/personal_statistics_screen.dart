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
            const SizedBox(height: 10),
            _buildDerivedChipsRow(context),
            const SizedBox(height: 14),
            _buildStatsGrid(context),
            const SizedBox(height: 14),
            _buildCareerHighlights(context),
          ],
        ),
      ),
    );
  }

  // ── Derived stats chips row ───────────────────────────────────────────────

  bool _userWon(GameStatistics g) => g.winningTeam == 'Team 1'
      ? g.team1Players.any((p) => p.name == user.username)
      : g.team2Players.any((p) => p.name == user.username);

  ({int length, bool isWin}) _currentStreak() {
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return (length: 0, isWin: true);
    final firstWon = _userWon(sorted.first);
    int count = 0;
    for (final g in sorted) {
      if (_userWon(g) == firstWon) {
        count++;
      } else {
        break;
      }
    }
    return (length: count, isWin: firstWon);
  }

  Widget _buildDerivedChipsRow(BuildContext context) {
    final totalGames = user.wins + user.losses;
    if (totalGames == 0) return const SizedBox.shrink();

    final avgCups = user.totalScore / totalGames;
    final avgThrows = user.totalThrows / totalGames;
    final streak = _currentStreak();
    final streakLabel =
        '${streak.length}-game ${streak.isWin ? 'W' : 'L'} streak';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _derivedChip(context, Icons.sports_bar, avgCups.toStringAsFixed(1),
              'cups/game', Colors.orange),
          const SizedBox(width: 8),
          _derivedChip(context, Icons.track_changes,
              avgThrows.toStringAsFixed(1), 'throws/game', Colors.blue),
          const SizedBox(width: 8),
          _derivedChip(
            context,
            streak.isWin
                ? Icons.trending_up
                : Icons.trending_down,
            streakLabel,
            '',
            streak.isWin ? Colors.green : Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _derivedChip(BuildContext context, IconData icon, String value,
      String label, Color color) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? value : '$value $label',
            style: TextStyle(
              color: c.onBackground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Career Highlights ─────────────────────────────────────────────────────

  Widget _buildCareerHighlights(BuildContext context) {
    final c = AppColors.of(context);
    if (games.isEmpty) return const SizedBox.shrink();

    // Best single-game hit rate
    double bestHitRate = 0;
    int mostCupsInGame = 0;
    for (final g in games) {
      final all = g.team1Players + g.team2Players;
      final p = all.where((p) => p.name == user.username).firstOrNull;
      if (p == null) continue;
      final hr = p.throws > 0 ? p.score / p.throws * 100 : 0.0;
      if (hr > bestHitRate) bestHitRate = hr;
      if (p.score.toInt() > mostCupsInGame) mostCupsInGame = p.score.toInt();
    }

    // Longest win streak
    final sorted = [...games]..sort((a, b) => a.date.compareTo(b.date));
    int longestStreak = 0;
    int current = 0;
    for (final g in sorted) {
      if (_userWon(g)) {
        current++;
        if (current > longestStreak) longestStreak = current;
      } else {
        current = 0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAREER HIGHLIGHTS',
          style: TextStyle(
            color: c.subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _highlightCard(
                context,
                '$longestStreak',
                'Best Streak',
                Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _highlightCard(
                context,
                '${bestHitRate.toStringAsFixed(0)}%',
                'Best Hit Rate',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _highlightCard(
                context,
                '$mostCupsInGame',
                'Most Cups',
                Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _highlightCard(
      BuildContext context, String value, String label, Color accent) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: accent, width: 3)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: c.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: c.subtle, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
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
    final recent = sorted.take(10).toList();
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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: recent.map((g) {
            final won = g.winningTeam == 'Team 1'
                ? g.team1Players.any((p) => p.name == user.username)
                : g.team2Players.any((p) => p.name == user.username);
            return Container(
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

  // ── 12-tile stat grid ────────────────────────────────────────────────────

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
    final avgCups = totalGames > 0 ? user.totalScore / totalGames : 0.0;

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
      _TileDef(
        Icons.shield_outlined,
        'Defended',
        '${user.defended}',
        Colors.indigo,
      ),
      _TileDef(
        Icons.thermostat,
        'Heating Up',
        '${user.totalHeatingUp}',
        Colors.orange.shade300,
      ),
      _TileDef(
        Icons.flag_rounded,
        'Last Cup',
        '${user.hitLastCup}',
        Colors.amber,
      ),
      _TileDef(
        Icons.bar_chart,
        'Avg/Game',
        avgCups.toStringAsFixed(1),
        Colors.grey,
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
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
