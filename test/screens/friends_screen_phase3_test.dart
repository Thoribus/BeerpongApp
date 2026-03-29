import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';

void main() {

  group('User.usernameLower in toJson', () {
    test('toJson includes usernameLower for Firestore prefix search', () {
      final user = User(id: 'u1', username: 'Alice');
      expect(user.toJson()['usernameLower'], 'alice');
    });

    test('usernameLower is always lowercase regardless of username casing', () {
      final user = User(id: 'u1', username: 'BeerPongKing');
      expect(user.toJson()['usernameLower'], 'beerpongking');
    });
  });
}
