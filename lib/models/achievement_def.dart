import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';

enum AchievementCategory {
  performance('Performance'),
  consistency('Consistency'),
  accuracy('Accuracy'),
  social('Social'),
  fun('Fun');

  const AchievementCategory(this.label);
  final String label;
}

/// Static definition of a single achievement.
class AchievementDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;

  /// Progress thresholds for [Bronze, Silver, Gold, Diamond].
  /// Single-element list = one-time badge (accuracy achievements).
  final List<int> thresholds;

  /// Display labels for each stage.
  final List<String> stageNames;

  /// Title granted when the user first reaches stage 1 (Bronze).
  final String? titleToGrant;

  /// Extracts the relevant metric from the user.
  final int Function(User) valueGetter;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.thresholds,
    required this.stageNames,
    required this.valueGetter,
    this.titleToGrant,
  });
}

/// Snapshot of one achievement's progress for a specific [User].
class AchievementProgress {
  final AchievementDef def;
  final int currentValue;

  /// 0 = locked, 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Diamond.
  final int currentStageIndex;

  const AchievementProgress({
    required this.def,
    required this.currentValue,
    required this.currentStageIndex,
  });

  bool get isLocked => currentStageIndex == 0;
  bool get isMaxed => currentStageIndex >= def.thresholds.length;

  /// Threshold for the next stage to unlock.
  int get nextThreshold =>
      isMaxed ? def.thresholds.last : def.thresholds[currentStageIndex];

  /// XP missing to the next stage threshold, used for "upcoming" sorting.
  int get gapToNextStage =>
      isMaxed ? 0 : (nextThreshold - currentValue).clamp(0, nextThreshold);

  /// Progress (0.0–1.0) within the current stage interval.
  double get progressToNextStage {
    if (isMaxed) return 1.0;
    final prevThreshold =
        currentStageIndex == 0 ? 0 : def.thresholds[currentStageIndex - 1];
    final nextT = def.thresholds[currentStageIndex];
    final range = nextT - prevThreshold;
    if (range <= 0) return 1.0;
    return ((currentValue - prevThreshold) / range).clamp(0.0, 1.0);
  }

  String get currentStageName =>
      isLocked ? 'Locked' : def.stageNames[currentStageIndex - 1];

  Color get stageColor {
    switch (currentStageIndex) {
      case 4:
        return const Color(0xFF00BCD4); // Diamond
      case 3:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFB0BEC5); // Silver
      case 1:
        return const Color(0xFF8D6E63); // Bronze
      default:
        return const Color(0xFF616161); // Locked
    }
  }
}
