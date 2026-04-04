import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/player.dart';

void main() {
  group('Player', () {
    test('isOnFire triggers at 3 consecutive hits and resets counter', () {
      final player = Player(name: 'Alice');
      player.consecutiveHits = 2;
      player.incrementHitThisRound(); // now 3
      expect(player.isOnFire(), isTrue);
      expect(player.consecutiveHits, 0); // reset
      expect(player.onFire, 1);
    });

    test('heatingUp increments when consecutiveHits reaches exactly 2', () {
      final player = Player(name: 'Alice');
      player.incrementHitThisRound(); // consecutiveHits = 1 → no heatingUp
      expect(player.heatingUp, 0);
      player.incrementHitThisRound(); // consecutiveHits = 2 → heatingUp!
      expect(player.heatingUp, 1);
      player.incrementHitThisRound(); // consecutiveHits = 3 → no extra heatingUp
      expect(player.heatingUp, 1);
    });

    test('heatingUp does not increment after a miss resets streak', () {
      final player = Player(name: 'Alice');
      player.incrementHitThisRound();
      player.incrementMisses(); // resets consecutiveHits
      player.incrementHitThisRound(); // back to 1, not 2
      expect(player.heatingUp, 0);
    });

    test('isOnFire returns false when below 3 consecutive hits', () {
      final player = Player(name: 'Alice');
      player.consecutiveHits = 2;
      expect(player.isOnFire(), isFalse);
    });

    test('incrementMisses resets consecutive hits', () {
      final player = Player(name: 'Alice', consecutiveHits: 2);
      player.incrementMisses();
      expect(player.consecutiveHits, 0);
      expect(player.misses, 1);
    });

    test('incrementAirballs increments both misses and airballs', () {
      final player = Player(name: 'Alice');
      player.incrementAirballs();
      expect(player.airballs, 1);
      expect(player.misses, 1);
    });

    test('toJson / fromJson round-trip preserves all stats including new fields', () {
      final player = Player(
        name: 'Bob',
        score: 5.0,
        throws: 10,
        misses: 3,
        airballs: 1,
        cupsHit: [0, 2, 4],
        consecutiveHits: 1,
        onFire: 2,
        heatingUp: 3,
        bounceAttempts: 4,
        bounceMakes: 2,
        islandAttempts: 3,
        islandMakes: 1,
        deathCupHits: 2,
        lastCupHit: true,
        isWinner: true,
      );

      final json = player.toJson();
      final restored = Player.fromJson(json);

      expect(restored.name, 'Bob');
      expect(restored.score, 5.0);
      expect(restored.throws, 10);
      expect(restored.misses, 3);
      expect(restored.airballs, 1);
      expect(restored.cupsHit, [0, 2, 4]);
      expect(restored.onFire, 2);
      expect(restored.heatingUp, 3);
      expect(restored.bounceAttempts, 4);
      expect(restored.bounceMakes, 2);
      expect(restored.islandAttempts, 3);
      expect(restored.islandMakes, 1);
      expect(restored.deathCupHits, 2);
      expect(restored.lastCupHit, isTrue);
      expect(restored.isWinner, isTrue);
    });

    test('fromJson defaults islandAttempts and deathCupHits to 0 when absent', () {
      final json = {
        'name': 'Alice', 'score': 2.0, 'throws': 5, 'misses': 1,
        'airballs': 0, 'hitThisRound': 0, 'cupsHit': [],
        'lastCupHit': false, 'isWinner': false,
      };
      final p = Player.fromJson(json);
      expect(p.islandAttempts, 0);
      expect(p.deathCupHits, 0);
    });

    test('mergedWith combines stats from two players with same name', () {
      final p1 = Player(
        name: 'Alice', score: 3, throws: 5, heatingUp: 1,
        bounceAttempts: 2, bounceMakes: 1,
        islandAttempts: 2, islandMakes: 1, deathCupHits: 1,
      );
      final p2 = Player(
        name: 'Alice', score: 2, throws: 4, heatingUp: 2,
        bounceAttempts: 1, bounceMakes: 1,
        islandAttempts: 1, islandMakes: 0, deathCupHits: 0,
      );
      final merged = p1.mergedWith(p2);
      expect(merged.score, 5);
      expect(merged.throws, 9);
      expect(merged.heatingUp, 3);
      expect(merged.bounceAttempts, 3);
      expect(merged.bounceMakes, 2);
      expect(merged.islandAttempts, 3);
      expect(merged.islandMakes, 1);
      expect(merged.deathCupHits, 1);
    });

    test('clone preserves islandAttempts and deathCupHits', () {
      final p = Player(name: 'Alice', islandAttempts: 4, deathCupHits: 2);
      final cloned = p.clone();
      expect(cloned.islandAttempts, 4);
      expect(cloned.deathCupHits, 2);
    });

    test('copyWithResetStats zeroes islandAttempts and deathCupHits', () {
      final p = Player(name: 'Alice', islandAttempts: 3, deathCupHits: 1);
      final reset = p.copyWithResetStats();
      expect(reset.islandAttempts, 0);
      expect(reset.deathCupHits, 0);
    });

    test('mergedWith throws on name mismatch', () {
      final p1 = Player(name: 'Alice');
      final p2 = Player(name: 'Bob');
      expect(() => p1.mergedWith(p2), throwsException);
    });

    test('incrementScoreBy adds fractional score', () {
      final p = Player(name: 'Alice', score: 1.0);
      p.incrementScoreBy(2.5);
      expect(p.score, closeTo(3.5, 0.001));
    });

    test('fromJson coerces bool hitThisRound to int', () {
      final json = <String, dynamic>{
        'name': 'Alice',
        'hitThisRound': true, // legacy bool field
        'score': 0.0,
        'throws': 0,
        'misses': 0,
        'airballs': 0,
        'cupsHit': <dynamic>[],
        'lastCupHit': false,
      };
      final p = Player.fromJson(json);
      expect(p.hitThisRound, 1);
    });

    test('operator == is true for same name regardless of other fields', () {
      final p1 = Player(name: 'Alice', score: 1.0);
      final p2 = Player(name: 'Alice', score: 5.0);
      // ignore: unrelated_type_equality_checks
      expect(p1 == p2, isTrue);
    });

    test('operator == is false for different names', () {
      final p1 = Player(name: 'Alice');
      final p2 = Player(name: 'Bob');
      expect(p1 == p2, isFalse);
    });

    test('hashCode is consistent with name', () {
      final p1 = Player(name: 'Alice');
      final p2 = Player(name: 'Alice');
      expect(p1.hashCode, p2.hashCode);
    });
  });
}
