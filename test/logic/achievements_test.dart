import 'package:beerpongapp/models/achievement_def.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/util/achievement_engine.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter/material.dart';

User makeUser({
  String username = 'TestUser',
  double totalScore = 0,
  int totalThrows = 0,
  int wins = 0,
  int losses = 0,
  int onFire = 0,
  int bounceAttempts = 0,
  int bounceMakes = 0,
  int islandAttempts = 0,
  int islandMakes = 0,
  int deathCupHits = 0,
  int defended = 0,
  int hitLastCup = 0,
  int totalHeatingUp = 0,
  int perfectGames = 0,
  int nightGames = 0,
  int bestWinStreak = 0,
  List<String> friends = const [],
  int xp = 0,
  Map<String, int> unlockedAchievementStages = const {},
  List<String> unlockedTitles = const [],
}) {
  return User(
    id: 'u1',
    username: username,
    totalScore: totalScore,
    totalThrows: totalThrows,
    wins: wins,
    losses: losses,
    onFire: onFire,
    bounceAttempts: bounceAttempts,
    bounceMakes: bounceMakes,
    islandAttempts: islandAttempts,
    islandMakes: islandMakes,
    deathCupHits: deathCupHits,
    defended: defended,
    hitLastCup: hitLastCup,
    totalHeatingUp: totalHeatingUp,
    perfectGames: perfectGames,
    nightGames: nightGames,
    bestWinStreak: bestWinStreak,
    friends: friends,
    xp: xp,
    unlockedAchievementStages: unlockedAchievementStages,
    unlockedTitles: List<String>.from(unlockedTitles),
  );
}

void main() {
  group('AchievementsScreen static API', () {
    test('checkAchievements is callable and no-ops when no stage changes', () async {
      final user = makeUser();
      final initialXp = user.xp;
      final initialTitles = List<String>.from(user.unlockedTitles);

      AchievementsScreen.checkAchievements(user);
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(user.xp, initialXp);
      expect(user.unlockedTitles, initialTitles);
    });

    test('getColorForUnlockedTitle returns grey for unknown title', () {
      final user = makeUser();
      final color = AchievementsScreen.getColorForUnlockedTitle(
        'Unknown Title',
        user,
      );
      expect(color, Colors.grey);
    });

    test('getColorForUnlockedTitle returns mapped stage color for unlocked title', () {
      final user = makeUser(totalScore: 800);
      final color = AchievementsScreen.getColorForUnlockedTitle(
        'Sharpshooter',
        user,
      );
      expect(color, const Color(0xFFFFD700));
    });
  });

  group('AchievementEngine smoke', () {
    test('catalogue has unique ids and all category buckets', () {
      final ids = AchievementEngine.allAchievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(
        AchievementEngine.allAchievements
            .map((a) => a.category)
            .toSet()
            .containsAll(AchievementCategory.values),
        isTrue,
      );
    });

    test('evaluate computes expected stages for boundary values', () {
      final user = makeUser(totalScore: 50, wins: 10, friends: const ['a', 'b', 'c']);
      final progress = AchievementEngine.evaluate(user);

      final cups = progress.firstWhere((p) => p.def.id == 'cups_hit');
      final wins = progress.firstWhere((p) => p.def.id == 'wins');
      final friends =
          progress.firstWhere((p) => p.def.id == 'friends_count');

      expect(cups.currentStageIndex, 1);
      expect(wins.currentStageIndex, 1);
      expect(friends.currentStageIndex, 1);
    });

    test('evaluateGrouped returns one entry per category', () {
      final user = makeUser();
      final grouped = AchievementEngine.evaluateGrouped(user);
      expect(grouped.keys.toSet(), containsAll(AchievementCategory.values));
      for (final cat in AchievementCategory.values) {
        expect(grouped[cat], isNotEmpty);
      }
    });

    test('evaluateGrouped entries belong to their declared category', () {
      final user = makeUser();
      final grouped = AchievementEngine.evaluateGrouped(user);
      for (final cat in AchievementCategory.values) {
        for (final p in grouped[cat]!) {
          expect(p.def.category, cat);
        }
      }
    });

    test('upcomingUnlocks returns non-maxed achievements sorted by gap', () {
      final user = makeUser(totalScore: 49); // 1 away from first cups_hit stage
      final upcoming = AchievementEngine.upcomingUnlocks(user);
      expect(upcoming, isNotEmpty);
      // Verify none of the returned achievements are maxed
      for (final p in upcoming) {
        expect(p.isMaxed, isFalse);
      }
      // Verify sorted ascending by gapToNextStage
      for (int i = 0; i < upcoming.length - 1; i++) {
        expect(
          upcoming[i].gapToNextStage,
          lessThanOrEqualTo(upcoming[i + 1].gapToNextStage),
        );
      }
    });

    test('upcomingUnlocks excludes maxed achievements', () {
      // Diamond cups_hit requires 2000 — very high user should max it
      final user = makeUser(totalScore: 2001);
      final upcoming = AchievementEngine.upcomingUnlocks(user);
      final cupsEntry = upcoming.where((p) => p.def.id == 'cups_hit');
      expect(cupsEntry, isEmpty);
    });
  });

  group('AchievementEngine accuracy valueGetters', () {
    test('hit_rate returns 0 when fewer than 20 games played', () {
      final def = AchievementEngine.allAchievements
          .firstWhere((d) => d.id == 'hit_rate');
      final user = makeUser(wins: 5, losses: 5); // 10 games total
      expect(def.valueGetter(user), 0);
    });

    test('hit_rate returns non-zero after 20 games with hits', () {
      final def = AchievementEngine.allAchievements
          .firstWhere((d) => d.id == 'hit_rate');
      final user = makeUser(
        wins: 10,
        losses: 10,
        totalScore: 1000,
        totalThrows: 1500,
      );
      expect(def.valueGetter(user), greaterThan(0));
    });

    test('bounce_accuracy returns 0 when fewer than 10 attempts', () {
      final def = AchievementEngine.allAchievements
          .firstWhere((d) => d.id == 'bounce_accuracy');
      final user = makeUser(bounceAttempts: 5, bounceMakes: 4);
      // User model maps to u.bounceAttempts — need to use the right field
      expect(def.valueGetter(user), 0);
    });

    test('island_accuracy returns 0 when fewer than 5 attempts', () {
      final def = AchievementEngine.allAchievements
          .firstWhere((d) => d.id == 'island_accuracy');
      final user = makeUser(islandAttempts: 2, islandMakes: 2);
      expect(def.valueGetter(user), 0);
    });

    test('island_accuracy returns correct percentage when criteria met', () {
      final def = AchievementEngine.allAchievements
          .firstWhere((d) => d.id == 'island_accuracy');
      // 10 attempts, 7 makes → 70%
      final user = makeUser(islandAttempts: 10, islandMakes: 7);
      expect(def.valueGetter(user), 70);
    });
  });
}
