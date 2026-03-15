import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRepository {
  FriendRepository._();
  static final FriendRepository instance = FriendRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<User>> getFriends(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];
      final data = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(data['friends'] ?? []);
      if (friendIds.isEmpty) return [];

      // Batch whereIn queries — Firestore supports up to 30 per query,
      // using 10 for a safe margin.
      const batchSize = 10;
      final friends = <User>[];

      for (int i = 0; i < friendIds.length; i += batchSize) {
        final batch = friendIds.skip(i).take(batchSize).toList();
        final snapshot = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          final userData = doc.data();
          friends.add(User.fromJson({...userData, 'id': doc.id}));
        }
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
