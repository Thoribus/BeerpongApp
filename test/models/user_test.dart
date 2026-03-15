import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';

void main() {
  group('User', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      final user = User(
        id: 'u1',
        username: 'Alice',
        title: 'Beer Pong King',
        avatarKey: 'avatar_catbeer',
        backgroundKey: 'bg_blue',
        totalScore: 42.0,
        totalMisses: 5,
        totalAirballs: 2,
        totalThrows: 20,
        onFire: 3,
        defended: 1,
        hitLastCup: 2,
        cupsHit: [0, 1, 2],
        wins: 7,
        losses: 3,
        friends: ['f1', 'f2'],
        unlockedTitles: ['title1'],
      );

      final json = user.toJson();
      final restored = User.fromJson({...json, 'id': 'u1'});

      expect(restored.id, 'u1');
      expect(restored.username, 'Alice');
      expect(restored.totalScore, 42.0);
      expect(restored.wins, 7);
      expect(restored.losses, 3);
      expect(restored.cupsHit, [0, 1, 2]);
      expect(restored.friends, ['f1', 'f2']);
    });

    test('winRate returns 0 when no games played', () {
      final user = User(id: 'u1', username: 'Bob');
      expect(user.winRate, 0.0);
    });

    test('winRate is correct with wins and losses', () {
      final user = User(id: 'u1', username: 'Bob', wins: 3, losses: 1);
      expect(user.winRate, closeTo(0.75, 0.001));
    });

    test('hitRate returns 0 when no throws', () {
      final user = User(id: 'u1', username: 'Bob');
      expect(user.hitRate, 0.0);
    });

    test('hitRate is totalScore / totalThrows', () {
      final user =
          User(id: 'u1', username: 'Bob', totalScore: 6, totalThrows: 10);
      expect(user.hitRate, closeTo(0.6, 0.001));
    });

    test('copyWith updates fields independently', () {
      final user = User(id: 'u1', username: 'Alice', wins: 2, losses: 1);
      final updated = user.copyWith(wins: 5);
      expect(updated.wins, 5);
      expect(updated.losses, 1); // unchanged
      expect(updated.username, 'Alice'); // unchanged
    });
  });
}
