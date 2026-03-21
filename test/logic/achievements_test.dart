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
  });
}
