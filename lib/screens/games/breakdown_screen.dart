import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BreakdownScreen extends StatelessWidget {
  final User user;
  final List<GameStatistics> games;

  const BreakdownScreen({super.key, required this.user, required this.games});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(context, context.loc.breakdownShotDistribution),
            _buildShotDonut(context),
            const SizedBox(height: 16),
            _sectionTitle(context, context.loc.breakdownSpecialShots),
            _buildSpecialShotCards(context),
            const SizedBox(height: 16),
            _sectionTitle(context, context.loc.breakdownWinContext),
            _buildWinContextSection(context),
            const SizedBox(height: 16),
            _sectionTitle(context, context.loc.breakdownHeadToHead),
            _buildHeadToHeadSection(context),
          ],
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: c.subtle,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Shot distribution donut ───────────────────────────────────────────────

  Widget _buildShotDonut(BuildContext context) {
    final c = AppColors.of(context);
    final total = user.totalThrows;
    if (total == 0) {
      return _emptyCard(context, context.loc.breakdownNoThrows);
    }

    final hits = user.totalScore.toInt();
    final airballs = user.totalAirballs;
    // Pure misses = misses that are not airballs
    final pureMisses = (user.totalMisses - user.totalAirballs).clamp(0, total);

    final sections = [
      PieChartSectionData(
        value: hits.toDouble(),
        color: Colors.green,
        title: hits > 0 ? '${(hits / total * 100).toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: pureMisses.toDouble(),
        color: Colors.redAccent,
        title: pureMisses > 0
            ? '${(pureMisses / total * 100).toStringAsFixed(0)}%'
            : '',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: airballs.toDouble(),
        color: Colors.blue,
        title: airballs > 0
            ? '${(airballs / total * 100).toStringAsFixed(0)}%'
            : '',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    ];

    return _card(
      context,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 3,
                    centerSpaceRadius: 48,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        color: c.onBackground,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(context.loc.breakdownThrowsLabel,
                        style: TextStyle(color: c.subtle, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(context.loc.breakdownHits, Colors.green),
              const SizedBox(width: 16),
              _legend(context.loc.liveStatMisses, Colors.redAccent),
              const SizedBox(width: 16),
              _legend(context.loc.liveStatAirballs, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  // ── Special shots breakdown ───────────────────────────────────────────────

  Widget _buildSpecialShotCards(BuildContext context) {
    return Column(
      children: [
        _shotCard(
          context,
          label: context.loc.breakdownBounceShot,
          accent: Colors.purple,
          makes: user.bounceMakes,
          attempts: user.bounceAttempts,
        ),
        const SizedBox(height: 8),
        _shotCard(
          context,
          label: context.loc.breakdownIslandShot,
          accent: Colors.teal,
          makes: user.islandMakes,
          attempts: user.islandAttempts,
        ),
        const SizedBox(height: 8),
        _shotCard(
          context,
          label: 'Defended',
          accent: Colors.indigo,
          makes: user.defended,
          attempts: null, // no attempt tracking — show total only
        ),
      ],
    );
  }

  Widget _shotCard(
    BuildContext context, {
    required String label,
    required Color accent,
    required int makes,
    required int? attempts,
  }) {
    final c = AppColors.of(context);
    final pct = (attempts != null && attempts > 0)
        ? makes / attempts
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: c.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 6),
                if (attempts != null && attempts > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct!.clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 6,
                    ),
                  )
                else
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                attempts != null
                    ? '$makes / $attempts'
                    : '$makes total',
                style: TextStyle(
                    color: c.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              if (pct != null)
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Win context ───────────────────────────────────────────────────────────

  Widget _buildWinContextSection(BuildContext context) {
    final c = AppColors.of(context);

    if (games.isEmpty || user.wins == 0) {
      return _emptyCard(context, 'No wins recorded yet.');
    }

    // Bucket wins by cupsRemainingWinner
    int dominant = 0; // ≥ 5
    int comfortable = 0; // 3–4
    int close = 0; // 1–2
    int clutch = user.hitLastCup; // won with the last cup

    for (final g in games) {
      final remaining = g.cupsRemainingWinner;
      if (remaining == null) continue;
      if (remaining >= 5) {
        dominant++;
      } else if (remaining >= 3) {
        comfortable++;
      } else if (remaining >= 1) {
        close++;
      }
    }

    final totalBucketed = dominant + comfortable + close;

    return Column(
      children: [
        if (totalBucketed > 0)
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.breakdownWinMarginTitle,
                    style: TextStyle(
                        color: c.onBackground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 12),
                _winBar(context, context.loc.breakdownDominant, dominant, totalBucketed,
                    Colors.green),
                const SizedBox(height: 8),
                _winBar(context, context.loc.breakdownComfortable, comfortable,
                    totalBucketed, Colors.amber),
                const SizedBox(height: 8),
                _winBar(context, context.loc.breakdownClose, close, totalBucketed,
                    Colors.redAccent),
              ],
            ),
          ),
        if (totalBucketed > 0) const SizedBox(height: 8),
        _card(
          context,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc.breakdownClutchRate,
                        style: TextStyle(
                            color: c.onBackground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text(context.loc.breakdownClutchDesc,
                        style: TextStyle(color: c.subtle, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                user.wins > 0
                    ? '${(clutch / user.wins * 100).toStringAsFixed(0)}%'
                    : '--',
                style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _winBar(BuildContext context, String label, int count, int total,
      Color color) {
    final c = AppColors.of(context);
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child:
              Text(label, style: TextStyle(color: c.subtle, fontSize: 11)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text('$count',
              style: TextStyle(
                  color: c.onBackground,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  // ── Head to head ─────────────────────────────────────────────────────────

  Widget _buildHeadToHeadSection(BuildContext context) {
    if (games.isEmpty) {
      return _emptyCard(context, context.loc.breakdownNoGames);
    }

    // Aggregate W/L per opponent
    final Map<String, ({int wins, int losses})> records = {};
    for (final g in games) {
      final userOnTeam1 = g.team1Players.any((p) => p.name == user.username);
      final userWon = g.winningTeam == (userOnTeam1 ? 'Team 1' : 'Team 2');
      final opponents = userOnTeam1 ? g.team2Players : g.team1Players;
      for (final opp in opponents) {
        final name = opp.name;
        if (name == user.username) continue;
        final prev = records[name] ?? (wins: 0, losses: 0);
        records[name] = userWon
            ? (wins: prev.wins + 1, losses: prev.losses)
            : (wins: prev.wins, losses: prev.losses + 1);
      }
    }

    if (records.isEmpty) {
      return _emptyCard(context, context.loc.breakdownNoOpponents);
    }

    // Sort by total games descending, cap at 5
    final sorted = records.entries.toList()
      ..sort((a, b) =>
          (b.value.wins + b.value.losses).compareTo(a.value.wins + a.value.losses));
    final top = sorted.take(5).toList();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _h2hRow(context, top[i].key, top[i].value.wins, top[i].value.losses),
          ],
        ],
      ),
    );
  }

  Widget _h2hRow(BuildContext context, String name, int wins, int losses) {
    final c = AppColors.of(context);
    final total = wins + losses;
    final winPct = total > 0 ? wins / total : 0.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      color: c.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: winPct.clamp(0.0, 1.0),
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.4),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$wins W – $losses L',
              style: TextStyle(
                  color: c.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            Text(
              '${(winPct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ],
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
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _emptyCard(BuildContext context, String message) {
    final c = AppColors.of(context);
    return _card(
      context,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message, style: TextStyle(color: c.subtle, fontSize: 13)),
        ),
      ),
    );
  }
}
