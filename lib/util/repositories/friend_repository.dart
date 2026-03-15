import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:beerpongapp/util/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRepository {
  FriendRepository._();
  static final FriendRepository instance = FriendRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<User>> getFriends(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(data['friends'] ?? []);

      final friends = <User>[];
      for (final friendId in friendIds) {
        final friend = await UserRepository.instance.getUser(friendId);
        if (friend != null) friends.add(friend);
      }
      return friends;
    } catch (e) {
      AppLogger.error('Error fetching friends', e);
      rethrow;
    }
  }

  Future<void> addFriend(String userId, String friendId) async {
    try {
      final userDoc = _db.collection('users').doc(userId);
      final friendDoc = _db.collection('users').doc(friendId);
      await _db.runTransaction((transaction) async {
        transaction.update(userDoc, {
          'friends': FieldValue.arrayUnion([friendId])
        });
        transaction.update(friendDoc, {
          'friends': FieldValue.arrayUnion([userId])
        });
      });
    } catch (e) {
      AppLogger.error('Error adding friend', e);
      rethrow;
    }
  }
}
