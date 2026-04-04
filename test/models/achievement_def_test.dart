import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/achievement_def.dart';
import 'package:beerpongapp/models/user.dart';

AchievementDef _makeDef({
  List<int> thresholds = const [10, 25, 50, 100],
  List<String>? stageNames,
}) =>
    AchievementDef(
      id: 'test-achievement',
      title: 'Test',
      description: 'A test achievement',
      icon: Icons.star,
      category: AchievementCategory.performance,
      thresholds: thresholds,
      stageNames: stageNames ?? ['Bronze', 'Silver', 'Gold', 'Diamond'],
      valueGetter: (u) => u.wins,
    );

AchievementProgress _progress(AchievementDef def, int value, int stage) =>
    AchievementProgress(def: def, currentValue: value, currentStageIndex: stage);

void main() {
  group('AchievementCategory', () {
    test('all 5 categories have distinct labels', () {
      final labels = AchievementCategory.values.map((c) => c.label).toSet();
      expect(labels.length, 5);
    });

    test('each category has a non-empty label', () {
      for (final cat in AchievementCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });
  });

  group('AchievementProgress.isLocked / isMaxed', () {
    test('stage 0 is locked', () {
      final prog = _progress(_makeDef(), 0, 0);
      expect(prog.isLocked, isTrue);
      expect(prog.isMaxed, isFalse);
    });

    test('stage 1 is not locked and not maxed (4-stage achievement)', () {
      final prog = _progress(_makeDef(), 10, 1);
      expect(prog.isLocked, isFalse);
      expect(prog.isMaxed, isFalse);
    });

    test('stage equal to threshold count is maxed', () {
      final def = _makeDef(); // 4 thresholds
      final prog = _progress(def, 100, 4);
      expect(prog.isMaxed, isTrue);
      expect(prog.isLocked, isFalse);
    });
  });

  group('AchievementProgress.nextThreshold', () {
    test('stage 0 → first threshold', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 0, 0);
      expect(prog.nextThreshold, 10);
    });

    test('stage 1 → second threshold', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 10, 1);
      expect(prog.nextThreshold, 25);
    });

    test('maxed → last threshold', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 100, 4);
      expect(prog.nextThreshold, 100); // isMaxed → returns last
    });
  });

  group('AchievementProgress.gapToNextStage', () {
    test('gap is 0 when maxed', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 100, 4);
      expect(prog.gapToNextStage, 0);
    });

    test('gap is threshold - currentValue when not maxed', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 7, 0); // need 10, have 7
      expect(prog.gapToNextStage, 3);
    });

    test('gap is clamped to 0 when value exceeds threshold', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 15, 0); // already past first threshold
      expect(prog.gapToNextStage, 0);
    });
  });

  group('AchievementProgress.progressToNextStage', () {
    test('returns 1.0 when maxed', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 100, 4);
      expect(prog.progressToNextStage, 1.0);
    });

    test('stage 0: progress = currentValue / firstThreshold', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 5, 0);
      expect(prog.progressToNextStage, closeTo(0.5, 0.001));
    });

    test('stage 1: progress is relative to previous threshold', () {
      // Stage 1: prev=10, next=25, range=15. value=17.5 → (17.5-10)/15 = 0.5
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      final prog = _progress(def, 17, 1);
      // (17-10)/(25-10) = 7/15 ≈ 0.467
      expect(prog.progressToNextStage, closeTo(7 / 15, 0.01));
    });

    test('progress is clamped to [0.0, 1.0]', () {
      final def = _makeDef(thresholds: [10, 25, 50, 100]);
      for (int v = 0; v <= 110; v += 10) {
        for (int s = 0; s <= 4; s++) {
          final prog = _progress(def, v, s);
          final p = prog.progressToNextStage;
          expect(p, inInclusiveRange(0.0, 1.0),
              reason: 'Out of range for value=$v stage=$s');
        }
      }
    });
  });

  group('AchievementProgress.currentStageName', () {
    test('locked stage returns "Locked"', () {
      final def = _makeDef();
      final prog = _progress(def, 0, 0);
      expect(prog.currentStageName, 'Locked');
    });

    test('stage 1 returns first stage name', () {
      final def = _makeDef(stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond']);
      final prog = _progress(def, 10, 1);
      expect(prog.currentStageName, 'Bronze');
    });

    test('stage 4 returns last stage name', () {
      final def = _makeDef(stageNames: ['Bronze', 'Silver', 'Gold', 'Diamond']);
      final prog = _progress(def, 100, 4);
      expect(prog.currentStageName, 'Diamond');
    });
  });

  group('AchievementProgress.stageColor', () {
    test('stage 0 (locked) returns grey color', () {
      final def = _makeDef();
      final prog = _progress(def, 0, 0);
      expect(prog.stageColor, const Color(0xFF616161));
    });

    test('stage 1 returns bronze color', () {
      final prog = _progress(_makeDef(), 10, 1);
      expect(prog.stageColor, const Color(0xFF8D6E63));
    });

    test('stage 2 returns silver color', () {
      final prog = _progress(_makeDef(), 25, 2);
      expect(prog.stageColor, const Color(0xFFB0BEC5));
    });

    test('stage 3 returns gold color', () {
      final prog = _progress(_makeDef(), 50, 3);
      expect(prog.stageColor, const Color(0xFFFFD700));
    });

    test('stage 4 returns diamond color', () {
      final prog = _progress(_makeDef(), 100, 4);
      expect(prog.stageColor, const Color(0xFF00BCD4));
    });
  });

  group('AchievementDef.valueGetter', () {
    test('valueGetter is called with user and returns correct metric', () {
      final def = AchievementDef(
        id: 'wins',
        title: 'Winner',
        description: 'Win games',
        icon: Icons.emoji_events,
        category: AchievementCategory.performance,
        thresholds: [5, 15, 30],
        stageNames: ['Bronze', 'Silver', 'Gold'],
        valueGetter: (u) => u.wins,
      );
      final user = User(id: 'u1', username: 'Alice', wins: 7);
      expect(def.valueGetter(user), 7);
    });
  });
}
