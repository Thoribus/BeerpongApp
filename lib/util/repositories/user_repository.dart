import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      AppLogger.error('Error adding user', e);
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      AppLogger.error('Error updating user', e);
      rethrow;
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return _userFromDoc(doc);
    } catch (e) {
      AppLogger.error('Error getting user', e);
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
    } catch (e) {
      AppLogger.error('Error deleting user', e);
      rethrow;
    }
  }

  User _userFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromJson({...data, 'id': doc.id});
  }

  /// Merge a player's in-game stats into their persistent user profile.
  Future<List<User>> saveGame({
    required List<Player> team1,
    required List<Player> team2,
  }) async {
    final updatedUsers = <User>[];
    for (final player in [...team1, ...team2]) {
      if (player.user == null) continue;
      final updatedUser = mapPlayerToUser(player);
      await updateUser(updatedUser);
      updatedUsers.add(updatedUser);
    }
    return updatedUsers;
  }

  /// Maps a player's in-game results onto their user profile by incrementing stats.
  static User mapPlayerToUser(Player player) {
    final oldUser = player.user!;
    return oldUser.copyWith(
      totalScore: oldUser.totalScore + player.score,
      totalMisses: oldUser.totalMisses + player.misses,
      totalAirballs: oldUser.totalAirballs + player.airballs,
      totalThrows: oldUser.totalThrows + player.throws,
      onFire: oldUser.onFire + player.onFire,
      defended: oldUser.defended + player.defended,
      hitLastCup: oldUser.hitLastCup + (player.lastCupHit ? 1 : 0),
      cupsHit: [...oldUser.cupsHit, ...player.cupsHit],
      wins: oldUser.wins + (player.isWinner ? 1 : 0),
      losses: oldUser.losses + (player.isWinner ? 0 : 1),
    );
  }
}
