import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/util/level_system.dart';

void main() {
  group('LevelSystem.calculateStarsGained', () {
    test('baseline participation awards 10 stars', () {
      final stars = LevelSystem.calculateStarsGained(
        isWinner: false,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: false,
      );
      expect(stars, 10);
    });

    test('win bonus adds 20 stars', () {
      final stars = LevelSystem.calculateStarsGained(
        isWinner: true,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: false,
      );
      expect(stars, 30); // 10 + 20
    });

    test('cups hit contribute 2 stars each', () {
      final stars = LevelSystem.calculateStarsGained(
        isWinner: false,
        cupsHit: 5,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: false,
      );
      expect(stars, 20); // 10 + 5*2
    });

    test('hitting last cup adds 30 stars', () {
      final stars = LevelSystem.calculateStarsGained(
        isWinner: false,
        cupsHit: 0,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: true,
      );
      expect(stars, 40); // 10 + 30
    });

    test('full performance game returns expected total', () {
      // win(20) + 6 cups(12) + 2 onFire(10) + 1 bounce(8) + 1 island(10)
      // + 1 deathCup(15) + lastCup(30) + base(10) = 115
      final stars = LevelSystem.calculateStarsGained(
        isWinner: true,
        cupsHit: 6,
        onFire: 2,
        bounceMakes: 1,
        islandMakes: 1,
        deathCupHits: 1,
        hitLastCup: true,
      );
      expect(stars, 115);
    });

    test('typical losing game (4 cups, no specials) is at least 10 stars', () {
      // 10 base + 4*2 = 18 — enough to make progress toward a 100-star item
      final stars = LevelSystem.calculateStarsGained(
        isWinner: false,
        cupsHit: 4,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: false,
      );
      expect(stars, greaterThanOrEqualTo(10));
    });

    test('typical winning game (5 cups, no specials) is in 30–80 range', () {
      // 10 base + 20 win + 5*2 = 40
      final stars = LevelSystem.calculateStarsGained(
        isWinner: true,
        cupsHit: 5,
        onFire: 0,
        bounceMakes: 0,
        islandMakes: 0,
        deathCupHits: 0,
        hitLastCup: false,
      );
      expect(stars, inInclusiveRange(30, 80));
    });
  });
}
