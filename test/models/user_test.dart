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
        cupsHitCount: {'0': 1, '1': 1, '2': 1},
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

    test('toJson / fromJson round-trip preserves islandAttempts and deathCupHits', () {
      final user = User(
        id: 'u1',
        username: 'Alice',
        islandAttempts: 5,
        deathCupHits: 3,
      );
      final json = user.toJson();
      final restored = User.fromJson({...json, 'id': 'u1'});
      expect(restored.islandAttempts, 5);
      expect(restored.deathCupHits, 3);
    });

    test('fromJson defaults islandAttempts and deathCupHits to 0 when absent', () {
      final restored = User.fromJson({'id': 'u1', 'username': 'Bob'});
      expect(restored.islandAttempts, 0);
      expect(restored.deathCupHits, 0);
    });

    test('copyWith updates islandAttempts independently', () {
      final user = User(id: 'u1', username: 'Alice', islandAttempts: 2, deathCupHits: 1);
      final updated = user.copyWith(islandAttempts: 7);
      expect(updated.islandAttempts, 7);
      expect(updated.deathCupHits, 1); // unchanged
    });

    group('lastGameAt', () {
      test('defaults to null when absent from JSON', () {
        final user = User.fromJson({'id': 'u1', 'username': 'Bob'});
        expect(user.lastGameAt, isNull);
      });

      test('parses from ISO-8601 string', () {
        final dt = DateTime.utc(2026, 3, 10, 12);
        final user = User.fromJson({
          'id': 'u1',
          'username': 'Bob',
          'lastGameAt': dt.toIso8601String(),
        });
        expect(user.lastGameAt, dt);
      });

      test('toJson does not include lastGameAt (server-managed field)', () {
        final user = User(
          id: 'u1',
          username: 'Alice',
          lastGameAt: DateTime.utc(2026, 3, 10),
        );
        expect(user.toJson().containsKey('lastGameAt'), isFalse);
      });

      test('copyWith preserves lastGameAt when not provided', () {
        final dt = DateTime.utc(2026, 3, 10);
        final user = User(id: 'u1', username: 'Alice', lastGameAt: dt);
        final updated = user.copyWith(username: 'Alice2');
        expect(updated.lastGameAt, dt);
      });

      test('copyWith can update lastGameAt', () {
        final original = DateTime.utc(2026, 3, 1);
        final newer = DateTime.utc(2026, 3, 15);
        final user = User(id: 'u1', username: 'Alice', lastGameAt: original);
        final updated = user.copyWith(lastGameAt: newer);
        expect(updated.lastGameAt, newer);
      });
    });

    group('usernameLower', () {
      test('toJson includes usernameLower for Firestore prefix search', () {
        final user = User(id: 'u1', username: 'Alice');
        expect(user.toJson()['usernameLower'], 'alice');
      });

      test('usernameLower is always lowercase regardless of username casing', () {
        final user = User(id: 'u1', username: 'BeerPongKing');
        expect(user.toJson()['usernameLower'], 'beerpongking');
      });
    });
  });
}
