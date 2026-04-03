import 'package:beerpongapp/models/achievement_def.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/achievement_engine.dart';
import 'package:beerpongapp/util/level_system.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  final User user;

  const AchievementsScreen({super.key, required this.user});

  // ── Backwards-compatible static API ────────────────────────────────────────

  /// Grants titles for newly reached achievement stages and persists to
  /// Firestore. Called by [GameController] after each game.
  static void checkAchievements(User user) =>
      AchievementEngine.checkAndGrantTitles(user);

  /// Returns the stage colour for the achievement associated with [titleToGrant].
  /// Used by [PlayerCardMini] to colour the title badge.
  static Color getColorForUnlockedTitle(String titleToGrant, User user) =>
      AchievementEngine.getColorForTitle(titleToGrant, user);

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final grouped = AchievementEngine.evaluateGrouped(user);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onBackground,
        title: Text(context.loc.statsAchievements),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _LevelCard(user: user),
          const SizedBox(height: 20),
          for (final category in AchievementCategory.values) ...[
            _CategoryHeader(
              category: category,
              progresses: grouped[category] ?? [],
            ),
            const SizedBox(height: 10),
            _AchievementGrid(
              progresses: grouped[category] ?? [],
              onTap: (p) => _showDetail(context, p),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, AchievementProgress p) {
    showDialog(
      context: context,
      builder: (_) => _AchievementDetailDialog(progress: p),
    );
  }
}

// ── Level card ────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final User user;
  const _LevelCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = LevelSystem.levelFromXp(user.xp);
    final tier = LevelSystem.tierForLevel(level);
    final progress = LevelSystem.progressInLevel(user.xp);
    final toNext = LevelSystem.xpToNextLevel(user.xp);
    final isMax = level >= LevelSystem.maxLevel;

    final allProgress = AchievementEngine.evaluate(user);
    final unlocked = allProgress.where((p) => !p.isLocked).length;
    final total = allProgress.length;

    return Card(
      color: c.card,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Level badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tier.color, tier.color.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tier.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      context.loc.labelLevelShort(level),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: c.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tier.displayName,
                        style: TextStyle(fontSize: 13, color: tier.color),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: c.border,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(tier.color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMax
                            ? context.loc.achievementsMaxLevel
                            : context.loc.achievementsXpProgress(user.xp, toNext, level + 1),
                        style: TextStyle(fontSize: 11, color: c.subtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatChip(
                    icon: Icons.emoji_events,
                    label: '$unlocked / $total',
                    sub: context.loc.statsAchievements)),
                Expanded(child: _StatChip(
                    icon: Icons.trending_up,
                    label: '${user.bestWinStreak}',
                    sub: context.loc.achievementsBestStreak)),
                Expanded(child: _StatChip(
                    icon: Icons.gps_fixed,
                    label: '${(user.hitRate * 100).toStringAsFixed(0)}%',
                    sub: context.loc.statHitRate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _StatChip(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c.onBackground,
                fontSize: 14)),
        Text(
          sub,
          style: TextStyle(fontSize: 10, color: c.subtle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Category header ────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementProgress> progresses;
  const _CategoryHeader(
      {required this.category, required this.progresses});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unlocked = progresses.where((p) => !p.isLocked).length;
    return Row(
      children: [
        Text(
          category.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.onBackground,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$unlocked / ${progresses.length}',
            style:
                const TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ),
      ],
    );
  }
}

// ── Achievement grid ───────────────────────────────────────────────────────────

class _AchievementGrid extends StatelessWidget {
  final List<AchievementProgress> progresses;
  final void Function(AchievementProgress) onTap;
  const _AchievementGrid({required this.progresses, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // GridView.count (non-lazy) avoids the shrinkWrap+builder extent bug on
    // Android where items at the end of the list may not be rendered.
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.78,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: progresses
          .map((p) => _AchievementCard(progress: p, onTap: onTap))
          .toList(),
    );
  }
}

// ── Achievement card ───────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementProgress progress;
  final void Function(AchievementProgress) onTap;
  const _AchievementCard({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final locked = p.isLocked;
    final cardColor = locked ? const Color(0xFF424242) : p.stageColor;

    return GestureDetector(
      onTap: () => onTap(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                    color: p.stageColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  p.def.icon,
                  size: 36,
                  color: locked
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.9),
                ),
                if (locked)
                  const Icon(Icons.lock, size: 16, color: Colors.white38),
              ],
            ),
            Flexible(
              child: Text(
                p.def.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: locked ? Colors.white38 : Colors.white,
                ),
              ),
            ),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.isMaxed
                        ? 1.0
                        : (p.currentValue / p.nextThreshold).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.black26,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      locked ? Colors.white24 : Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  p.isMaxed
                      ? context.loc.achievementMaxed
                      : '${p.currentValue} / ${p.nextThreshold}',
                  style: TextStyle(
                    fontSize: 10,
                    color: locked ? Colors.white30 : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail dialog ──────────────────────────────────────────────────────────────

class _AchievementDetailDialog extends StatelessWidget {
  final AchievementProgress progress;
  const _AchievementDetailDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final c = AppColors.of(context);
    final stageLabels = [context.loc.achievementStagesBronze, context.loc.achievementStagesSilver, context.loc.achievementStagesGold, context.loc.achievementStagesDiamond];

    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(p.def.icon, color: p.stageColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(p.def.title,
                style: TextStyle(
                    color: c.onBackground, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.def.description,
              style: TextStyle(color: c.subtle, fontSize: 13)),
          const SizedBox(height: 16),
          // Stage progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < p.def.thresholds.length; i++) ...[
                _StageDot(
                  label: stageLabels[i],
                  threshold: p.def.thresholds[i],
                  unlocked: p.currentStageIndex > i,
                  isCurrent: p.currentStageIndex == i + 1,
                  stageIndex: i + 1,
                ),
                if (i < p.def.thresholds.length - 1)
                  // Padding(top: 13) centres the 2px line on the 28px dot
                  // circle: (28 / 2) - (2 / 2) = 13.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Container(
                        height: 2,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            p.isMaxed
                ? context.loc.achievementFullyMastered
                : context.loc.achievementProgress(p.currentValue, p.nextThreshold),
            style:
                TextStyle(color: c.onBackground, fontWeight: FontWeight.w600),
          ),
          if (!p.isMaxed) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p.isMaxed
                    ? 1.0
                    : (p.currentValue / p.nextThreshold).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: c.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(p.stageColor),
              ),
            ),
          ],
          if (p.def.titleToGrant != null) ...[
            const SizedBox(height: 12),
            Text(
              context.loc.achievementUnlocksTitle(p.def.titleToGrant!),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.amber,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.btnClose, style: TextStyle(color: c.onBackground)),
        ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  final String label;
  final int threshold;
  final bool unlocked;
  final bool isCurrent;
  final int stageIndex;

  const _StageDot({
    required this.label,
    required this.threshold,
    required this.unlocked,
    required this.isCurrent,
    required this.stageIndex,
  });

  Color get _color {
    switch (stageIndex) {
      case 4:
        return const Color(0xFF00BCD4);
      case 3:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFF8D6E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? _color : Colors.grey.shade800,
            border: isCurrent
                ? Border.all(color: _color, width: 2)
                : null,
          ),
          child: unlocked
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: unlocked ? _color : Colors.grey.shade600)),
        Text('$threshold',
            style: TextStyle(
                fontSize: 9,
                color: unlocked ? _color : Colors.grey.shade600)),
      ],
    );
  }
}
