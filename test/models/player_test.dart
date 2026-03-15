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

    test('toJson / fromJson round-trip preserves all stats', () {
      final player = Player(
        name: 'Bob',
        score: 5.0,
        throws: 10,
        misses: 3,
        airballs: 1,
        cupsHit: [0, 2, 4],
        consecutiveHits: 1,
        onFire: 2,
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
      expect(restored.lastCupHit, isTrue);
      expect(restored.isWinner, isTrue);
    });

    test('mergedWith combines stats from two players with same name', () {
      final p1 = Player(name: 'Alice', score: 3, throws: 5);
      final p2 = Player(name: 'Alice', score: 2, throws: 4);
      final merged = p1.mergedWith(p2);
      expect(merged.score, 5);
      expect(merged.throws, 9);
    });

    test('mergedWith throws on name mismatch', () {
      final p1 = Player(name: 'Alice');
      final p2 = Player(name: 'Bob');
      expect(() => p1.mergedWith(p2), throwsException);
    });
  });
}
