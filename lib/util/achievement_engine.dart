import 'package:beerpongapp/models/achievement_def.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';

/// Evaluates achievements and manages title unlocks.
///
/// All achievements are defined here as a single static catalogue so that
/// adding a new achievement only requires editing this one file.
class AchievementEngine {
  AchievementEngine._();

  // ── Achievement catalogue ──────────────────────────────────────────────────

  static final List<AchievementDef> allAchievements = [
    // ── Performance ──────────────────────────────────────────────────────────
    AchievementDef(
      id: 'cups_hit',
      title: 'Sniper',
      description: 'Sink N cups in total.',
      icon: Icons.sports_bar,
      category: AchievementCategory.performance,
      thresholds: [50, 250, 750, 2000],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Sharpshooter',
      valueGetter: (u) => u.totalScore.round(),
    ),
    AchievementDef(
      id: 'on_fire',
      title: 'Pyromaniac',
      description: 'Trigger On Fire N times (3 consecutive hits).',
      icon: Icons.local_fire_department,
      category: AchievementCategory.performance,
      thresholds: [5, 25, 100, 300],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'On Fire',
      valueGetter: (u) => u.onFire,
    ),
    AchievementDef(
      id: 'bounce_makes',
      title: 'Bounce King',
      description: 'Sink N cups via bounce shots.',
      icon: Icons.sports_volleyball,
      category: AchievementCategory.performance,
      thresholds: [5, 25, 75, 200],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Bounce Artist',
      valueGetter: (u) => u.bounceMakes,
    ),
    AchievementDef(
      id: 'island_makes',
      title: 'Island Ruler',
      description: 'Hit N island shots.',
      icon: Icons.landscape,
      category: AchievementCategory.performance,
      thresholds: [3, 15, 50, 100],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Island Master',
      valueGetter: (u) => u.islandMakes,
    ),
    AchievementDef(
      id: 'death_cups',
      title: 'Grim Reaper',
      description: 'Trigger N death cups.',
      icon: Icons.dangerous,
      category: AchievementCategory.performance,
      thresholds: [1, 5, 20, 50],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Death Bringer',
      valueGetter: (u) => u.deathCupHits,
    ),
    AchievementDef(
      id: 'defended',
      title: 'Guardian',
      description: 'Defend N cups.',
      icon: Icons.shield,
      category: AchievementCategory.performance,
      thresholds: [5, 25, 100, 250],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'The Wall',
      valueGetter: (u) => u.defended,
    ),
    AchievementDef(
      id: 'last_cup',
      title: 'Closer',
      description: 'Sink the winning cup N times.',
      icon: Icons.sports_score,
      category: AchievementCategory.performance,
      thresholds: [1, 10, 30, 75],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Clutch',
      valueGetter: (u) => u.hitLastCup,
    ),
    AchievementDef(
      id: 'heating_up',
      title: 'Heating Up',
      description: 'Reach 2 consecutive hits N times.',
      icon: Icons.whatshot,
      category: AchievementCategory.performance,
      thresholds: [10, 50, 200, 500],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Warming Up',
      valueGetter: (u) => u.totalHeatingUp,
    ),

    // ── Consistency ───────────────────────────────────────────────────────────
    AchievementDef(
      id: 'games_played',
      title: 'Veteran',
      description: 'Play N games.',
      icon: Icons.sports_bar_outlined,
      category: AchievementCategory.consistency,
      thresholds: [10, 50, 150, 500],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Regular',
      valueGetter: (u) => u.wins + u.losses,
    ),
    AchievementDef(
      id: 'wins',
      title: 'Winner',
      description: 'Win N games.',
      icon: Icons.emoji_events,
      category: AchievementCategory.consistency,
      thresholds: [10, 50, 150, 400],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Victor',
      valueGetter: (u) => u.wins,
    ),
    AchievementDef(
      id: 'win_streak',
      title: 'On a Roll',
      description: 'Reach a N-game win streak.',
      icon: Icons.trending_up,
      category: AchievementCategory.consistency,
      thresholds: [3, 5, 10, 15],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Unstoppable',
      valueGetter: (u) => u.bestWinStreak,
    ),
    AchievementDef(
      id: 'perfect_games',
      title: 'Perfection',
      description: 'Finish N games without a single miss.',
      icon: Icons.star,
      category: AchievementCategory.consistency,
      thresholds: [1, 5, 20, 50],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Flawless',
      valueGetter: (u) => u.perfectGames,
    ),
    AchievementDef(
      id: 'night_games',
      title: 'Night Owl',
      description: 'Play N games after 11 PM.',
      icon: Icons.nightlight_round,
      category: AchievementCategory.consistency,
      thresholds: [5, 20, 50, 100],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Vampire',
      valueGetter: (u) => u.nightGames,
    ),

    // ── Accuracy (rate-based, min. games guard built into valueGetter) ────────
    AchievementDef(
      id: 'hit_rate',
      title: 'Precision',
      description: 'Maintain a high hit rate across 20+ games. '
          'Value shows your hit rate × 100.',
      icon: Icons.gps_fixed,
      category: AchievementCategory.accuracy,
      thresholds: [50, 60, 70, 80],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Laser',
      valueGetter: (u) {
        final games = u.wins + u.losses;
        if (games < 20) return 0;
        return (u.hitRate * 100).round();
      },
    ),
    AchievementDef(
      id: 'bounce_accuracy',
      title: 'Trick Shot',
      description: 'Achieve high bounce shot accuracy (10+ attempts). '
          'Value shows accuracy × 100.',
      icon: Icons.control_camera,
      category: AchievementCategory.accuracy,
      thresholds: [40, 55, 70],
      stageNames: ['Bronze', 'Silver', 'Gold'],
      titleToGrant: 'Trick Artist',
      valueGetter: (u) {
        if (u.bounceAttempts < 10) return 0;
        return (u.bounceMakes / u.bounceAttempts * 100).round();
      },
    ),
    AchievementDef(
      id: 'island_accuracy',
      title: 'Island Precision',
      description: 'Achieve high island shot accuracy (5+ attempts). '
          'Value shows accuracy × 100.',
      icon: Icons.adjust,
      category: AchievementCategory.accuracy,
      thresholds: [40, 55, 70],
      stageNames: ['Bronze', 'Silver', 'Gold'],
      titleToGrant: 'Island Ace',
      valueGetter: (u) {
        if (u.islandAttempts < 5) return 0;
        return (u.islandMakes / u.islandAttempts * 100).round();
      },
    ),

    // ── Social ────────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'friends_count',
      title: 'Social Butterfly',
      description: 'Add N friends.',
      icon: Icons.group,
      category: AchievementCategory.social,
      thresholds: [3, 10, 25, 50],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Social Butterfly',
      valueGetter: (u) => u.friends.length,
    ),

    // ── Fun ───────────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'airballs',
      title: 'Airball Artist',
      description: 'Throw N airballs (ironic badge of honour).',
      icon: Icons.air,
      category: AchievementCategory.fun,
      thresholds: [10, 50, 150, 300],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Air Guitarist',
      valueGetter: (u) => u.totalAirballs,
    ),
    AchievementDef(
      id: 'warrior',
      title: 'Warrior',
      description: 'Lose N games — persistence is its own reward.',
      icon: Icons.military_tech,
      category: AchievementCategory.fun,
      thresholds: [10, 50, 150, 300],
      stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond'],
      titleToGrant: 'Resilient',
      valueGetter: (u) => u.losses,
    ),
  ];

  // ── Evaluation ─────────────────────────────────────────────────────────────

  /// Returns a [AchievementProgress] for every achievement in [allAchievements].
  static List<AchievementProgress> evaluate(User user) {
    return allAchievements.map((def) {
      final value = def.valueGetter(user);
      return AchievementProgress(
        def: def,
        currentValue: value,
        currentStageIndex: _computeStage(value, def.thresholds),
      );
    }).toList();
  }

  /// Returns achievements grouped by category, preserving catalogue order within each group.
  static Map<AchievementCategory, List<AchievementProgress>> evaluateGrouped(
      User user) {
    final all = evaluate(user);
    final map = <AchievementCategory, List<AchievementProgress>>{};
    for (final cat in AchievementCategory.values) {
      map[cat] = all.where((p) => p.def.category == cat).toList();
    }
    return map;
  }

  /// Returns the 3 non-maxed achievements closest to their next stage threshold.
  static List<AchievementProgress> upcomingUnlocks(User user) {
    return evaluate(user)
        .where((p) => !p.isMaxed)
        .toList()
      ..sort((a, b) => a.gapToNextStage.compareTo(b.gapToNextStage));
  }

  // ── Title management ───────────────────────────────────────────────────────

  /// Grants titles and awards XP for any newly reached achievement stages,
  /// then persists to Firestore. Safe to call repeatedly — already-unlocked
  /// stages are skipped.
  static Future<void> checkAndGrantTitles(User user) async {
    bool changed = false;
    int xpBonus = 0;

    final updatedStages = Map<String, int>.from(user.unlockedAchievementStages);

    for (final progress in evaluate(user)) {
      final id = progress.def.id;
      final prevStage = updatedStages[id] ?? 0;
      final currStage = progress.currentStageIndex;

      if (currStage > prevStage) {
        // Award XP for every newly crossed stage threshold.
        for (int s = prevStage + 1; s <= currStage; s++) {
          xpBonus += _xpForStage(s);
        }
        updatedStages[id] = currStage;
        changed = true;
      }

      // Grant the display title when Bronze is first reached.
      final title = progress.def.titleToGrant;
      if (title != null &&
          currStage >= 1 &&
          !user.unlockedTitles.contains(title)) {
        user.unlockedTitles.add(title);
        changed = true;
      }
    }

    if (changed) {
      user.unlockedAchievementStages = updatedStages;
      user.xp += xpBonus;
      await FirestoreService.instance.updateUser(user);
    }
  }

  static int _xpForStage(int stageIndex) {
    switch (stageIndex) {
      case 4:
        return 400; // Diamond
      case 3:
        return 200; // Gold
      case 2:
        return 100; // Silver
      default:
        return 50; // Bronze
    }
  }

  /// Returns the stage color for the achievement that grants [title].
  static Color getColorForTitle(String title, User user) {
    for (final p in evaluate(user)) {
      if (p.def.titleToGrant == title) return p.stageColor;
    }
    return Colors.grey;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static int _computeStage(int value, List<int> thresholds) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (value >= thresholds[i]) return i + 1;
    }
    return 0;
  }
}
