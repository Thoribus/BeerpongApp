import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/user_provider.dart';

void main() {
  group('UserProvider — pure logic (no Firebase)', () {
    test('initial user is null', () {
      final provider = UserProvider();
      expect(provider.user, isNull);
    });

    test('isLoading is true initially', () {
      final provider = UserProvider();
      expect(provider.isLoading, isTrue);
    });

    test('setUserForTesting sets user and notifies listeners', () {
      final provider = UserProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      final user = User(id: 'u1', username: 'Alice');
      provider.setUserForTesting(user);

      expect(provider.user?.id, 'u1');
      expect(notified, isTrue);
    });

    test('refreshUser early-returns without error when user is null', () async {
      final provider = UserProvider();
      // _user is null → should return immediately without calling Firestore
      await expectLater(provider.refreshUser(), completes);
    });

    test('equipItem early-returns without error when user is null', () async {
      final provider = UserProvider();
      await expectLater(
        provider.equipItem(field: 'activeCupSkin', itemId: 'skin1'),
        completes,
      );
    });

    test('claimUsername early-returns without error when user is null', () async {
      final provider = UserProvider();
      await expectLater(provider.claimUsername('NewName'), completes);
    });
  });
}
