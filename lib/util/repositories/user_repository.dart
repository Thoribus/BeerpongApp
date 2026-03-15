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
  /// Uses Firestore transactions with FieldValue.increment() to avoid race conditions.
  Future<List<User>> saveGame({
    required List<Player> team1,
    required List<Player> team2,
  }) async {
    final allPlayers =
        [...team1, ...team2].where((p) => p.user != null).toList();

    await Future.wait(allPlayers.map((player) async {
      final userRef = _db.collection('users').doc(player.user!.id);
      await _db.runTransaction((tx) async {
        tx.update(userRef, {
          'totalScore': FieldValue.increment(player.score),
          'totalMisses': FieldValue.increment(player.misses),
          'totalAirballs': FieldValue.increment(player.airballs),
          'totalThrows': FieldValue.increment(player.throws),
          'onFire': FieldValue.increment(player.onFire),
          'defended': FieldValue.increment(player.defended),
          'hitLastCup': FieldValue.increment(player.lastCupHit ? 1 : 0),
          'wins': FieldValue.increment(player.isWinner ? 1 : 0),
          'losses': FieldValue.increment(player.isWinner ? 0 : 1),
          for (final cupIndex in player.cupsHit)
            'cupsHitCount.$cupIndex': FieldValue.increment(1),
        });
      });
    }));

    final updatedUsers = await Future.wait(
      allPlayers.map((p) => getUser(p.user!.id)),
    );
    return updatedUsers.whereType<User>().toList();
  }

  /// Maps a player's in-game results onto their user profile by incrementing stats.
  /// Kept for backwards compatibility (used by AchievementsScreen).
  static User mapPlayerToUser(Player player) {
    final oldUser = player.user!;
    final updatedCupsHitCount = Map<String, int>.from(oldUser.cupsHitCount);
    for (final cupIndex in player.cupsHit) {
      final key = cupIndex.toString();
      updatedCupsHitCount[key] = (updatedCupsHitCount[key] ?? 0) + 1;
    }
    return oldUser.copyWith(
      totalScore: oldUser.totalScore + player.score,
      totalMisses: oldUser.totalMisses + player.misses,
      totalAirballs: oldUser.totalAirballs + player.airballs,
      totalThrows: oldUser.totalThrows + player.throws,
      onFire: oldUser.onFire + player.onFire,
      defended: oldUser.defended + player.defended,
      hitLastCup: oldUser.hitLastCup + (player.lastCupHit ? 1 : 0),
      cupsHitCount: updatedCupsHitCount,
      wins: oldUser.wins + (player.isWinner ? 1 : 0),
      losses: oldUser.losses + (player.isWinner ? 0 : 1),
    );
  }
}
