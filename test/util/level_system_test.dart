import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/util/level_system.dart';

void main() {
  group('LevelSystem.xpRequiredForLevel', () {
    test('level 1 requires 0 XP', () {
      expect(LevelSystem.xpRequiredForLevel(1), 0);
    });

    test('level 2 requires 100 XP', () {
      expect(LevelSystem.xpRequiredForLevel(2), 100);
    });

    test('level 3 requires 150 XP', () {
      expect(LevelSystem.xpRequiredForLevel(3), 150);
    });

    test('level 10 requires 500 XP', () {
      // 100 + (10-2)*50 = 100 + 400 = 500
      expect(LevelSystem.xpRequiredForLevel(10), 500);
    });

    test('increases linearly by 50 per level', () {
      final diff = LevelSystem.xpRequiredForLevel(5) - LevelSystem.xpRequiredForLevel(4);
      expect(diff, 50);
    });
  });

  group('LevelSystem.cumulativeXpForLevel', () {
    test('level 1 needs 0 cumulative XP', () {
      expect(LevelSystem.cumulativeXpForLevel(1), 0);
    });

    test('level 2 needs 100 cumulative XP', () {
      expect(LevelSystem.cumulativeXpForLevel(2), 100);
    });

    test('level 10 cumulative XP matches documented value', () {
      // Documented: Level 10 → cumulative 2,700
      expect(LevelSystem.cumulativeXpForLevel(10), 2700);
    });

    test('cumulative is strictly increasing', () {
      for (int i = 1; i < LevelSystem.maxLevel; i++) {
        expect(
          LevelSystem.cumulativeXpForLevel(i + 1),
          greaterThan(LevelSystem.cumulativeXpForLevel(i)),
        );
      }
    });
  });

  group('LevelSystem.levelFromXp', () {
    test('0 XP is level 1', () {
      expect(LevelSystem.levelFromXp(0), 1);
    });

    test('negative XP is level 1', () {
      expect(LevelSystem.levelFromXp(-100), 1);
    });

    test('exactly 100 XP reaches level 2', () {
      expect(LevelSystem.levelFromXp(100), 2);
    });

    test('99 XP stays at level 1', () {
      expect(LevelSystem.levelFromXp(99), 1);
    });

    test('huge XP caps at maxLevel', () {
      expect(LevelSystem.levelFromXp(999999), LevelSystem.maxLevel);
    });

    test('cumulative XP for level N gives exactly level N', () {
      for (int n = 1; n <= 20; n++) {
        final xp = LevelSystem.cumulativeXpForLevel(n);
        expect(LevelSystem.levelFromXp(xp), n,
            reason: 'Expected level $n for cumulative XP $xp');
      }
    });
  });

  group('LevelSystem.progressInLevel', () {
    test('0 XP has 0 progress', () {
      expect(LevelSystem.progressInLevel(0), 0.0);
    });

    test('exactly at level threshold is 0.0 progress', () {
      final xp = LevelSystem.cumulativeXpForLevel(3);
      expect(LevelSystem.progressInLevel(xp), 0.0);
    });

    test('halfway between two levels is ~0.5', () {
      final base = LevelSystem.cumulativeXpForLevel(2);
      final next = LevelSystem.cumulativeXpForLevel(3);
      final mid = base + (next - base) ~/ 2;
      expect(LevelSystem.progressInLevel(mid), closeTo(0.5, 0.01));
    });

    test('at maxLevel returns 1.0', () {
      final xp = LevelSystem.cumulativeXpForLevel(LevelSystem.maxLevel);
      expect(LevelSystem.progressInLevel(xp), 1.0);
    });

    test('progress is clamped to [0.0, 1.0]', () {
      for (int xp = 0; xp <= 10000; xp += 500) {
        final p = LevelSystem.progressInLevel(xp);
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('LevelSystem.xpToNextLevel', () {
    test('at level 1 with 0 XP needs 100 XP for level 2', () {
      expect(LevelSystem.xpToNextLevel(0), 100);
    });

    test('at exactly next threshold needs 0 extra XP', () {
      // At cumulativeXpForLevel(3) you are exactly at level 3, need xpRequiredForLevel(4)
      final xpAtLevel3 = LevelSystem.cumulativeXpForLevel(3);
      expect(LevelSystem.xpToNextLevel(xpAtLevel3),
          LevelSystem.cumulativeXpForLevel(4) - xpAtLevel3);
    });

    test('at maxLevel returns 0', () {
      final xp = LevelSystem.cumulativeXpForLevel(LevelSystem.maxLevel);
      expect(LevelSystem.xpToNextLevel(xp), 0);
    });
  });

  group('LevelSystem.tierForLevel', () {
    test('level 1-5 is benchWarmer', () {
      for (int l = 1; l <= 5; l++) {
        expect(LevelSystem.tierForLevel(l), LevelTier.benchWarmer,
            reason: 'Level $l should be benchWarmer');
      }
    });

    test('level 6-10 is partyStarter', () {
      for (int l = 6; l <= 10; l++) {
        expect(LevelSystem.tierForLevel(l), LevelTier.partyStarter,
            reason: 'Level $l should be partyStarter');
      }
    });

    test('level 11-15 is cupHunter', () {
      expect(LevelSystem.tierForLevel(11), LevelTier.cupHunter);
      expect(LevelSystem.tierForLevel(15), LevelTier.cupHunter);
    });

    test('level 16-20 is tableRegular', () {
      expect(LevelSystem.tierForLevel(16), LevelTier.tableRegular);
      expect(LevelSystem.tierForLevel(20), LevelTier.tableRegular);
    });

    test('level 21-25 is foamRoller', () {
      expect(LevelSystem.tierForLevel(21), LevelTier.foamRoller);
      expect(LevelSystem.tierForLevel(25), LevelTier.foamRoller);
    });

    test('level 26-30 is bounceArtist', () {
      expect(LevelSystem.tierForLevel(26), LevelTier.bounceArtist);
      expect(LevelSystem.tierForLevel(30), LevelTier.bounceArtist);
    });

    test('level 31-35 is deathCupDealer', () {
      expect(LevelSystem.tierForLevel(31), LevelTier.deathCupDealer);
      expect(LevelSystem.tierForLevel(35), LevelTier.deathCupDealer);
    });

    test('level 36-40 is pongVeteran', () {
      expect(LevelSystem.tierForLevel(36), LevelTier.pongVeteran);
      expect(LevelSystem.tierForLevel(40), LevelTier.pongVeteran);
    });

    test('level 41-45 is islandMaster', () {
      expect(LevelSystem.tierForLevel(41), LevelTier.islandMaster);
      expect(LevelSystem.tierForLevel(45), LevelTier.islandMaster);
    });

    test('level 46-50 is pongLegend', () {
      expect(LevelSystem.tierForLevel(46), LevelTier.pongLegend);
      expect(LevelSystem.tierForLevel(50), LevelTier.pongLegend);
    });

    test('all tiers have distinct display names', () {
      final names = LevelTier.values.map((t) => t.displayName).toSet();
      expect(names.length, LevelTier.values.length);
    });
  });

  group('LevelSystem.calculateXpGained', () {
    test('baseline participation gives 30 XP', () {
      final xp = LevelSystem.calculateXpGained(
        isWinner: false,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 0,
      );
      expect(xp, 30);
    });

    test('win adds 80 XP', () {
      final xp = LevelSystem.calculateXpGained(
        isWinner: true,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 0,
      );
      expect(xp, 110); // 30 + 80
    });

    test('cupsHit contribute 5 XP each', () {
      final xp = LevelSystem.calculateXpGained(
        isWinner: false,
        cupsHit: 4,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 0,
      );
      expect(xp, 50); // 30 + 4*5
    });

    test('hitLastCup adds 50 XP', () {
      final xp = LevelSystem.calculateXpGained(
        isWinner: false,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: true,
        newStreak: 0,
      );
      expect(xp, 80); // 30 + 50
    });

    test('streak bonus only applies to winners with streak >= 3', () {
      final xpNoStreak = LevelSystem.calculateXpGained(
        isWinner: true,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 2,
      );
      final xpWithStreak = LevelSystem.calculateXpGained(
        isWinner: true,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 3,
      );
      // streak=2: no bonus; streak=3: +1*20
      expect(xpNoStreak, 110);
      expect(xpWithStreak, 130);
    });

    test('loser gets no streak bonus even with high streak', () {
      final xp = LevelSystem.calculateXpGained(
        isWinner: false,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        defended: 0,
        hitLastCup: false,
        newStreak: 10,
      );
      expect(xp, 30); // no streak bonus without win
    });

    test('full-performance game total is correct', () {
      // 30 base + 80 win + 6*5 cups + 2*25 onFire + 1*15 bounce
      // + 1*20 island + 1*30 deathCup + 1*10 defended + 50 lastCup
      // + (3-2)*20 streak = 30+80+30+50+15+20+30+10+50+20 = 335
      final xp = LevelSystem.calculateXpGained(
        isWinner: true,
        cupsHit: 6,
        onFire: 2,
        bounceMakes: 1,
        islandMakes: 1,
        deathCupHits: 1,
        defended: 1,
        hitLastCup: true,
        newStreak: 3,
      );
      expect(xp, 335);
    });
  });
}
