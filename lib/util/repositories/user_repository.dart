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

  /// Returns true if [usernameLower] is unclaimed or already owned by [currentUserId].
  Future<bool> checkUsernameAvailable(
      String usernameLower, String currentUserId) async {
    final doc =
        await _db.collection('usernames').doc(usernameLower).get();
    if (!doc.exists) return true;
    return doc.data()?['uid'] == currentUserId;
  }

  /// Atomically releases the old username claim, claims the new one,
  /// and writes the updated username field on the user document.
  Future<void> claimUsername({
    required String newUsername,
    required String oldUsernameLower,
    required String uid,
  }) async {
    final newLower = newUsername.toLowerCase();
    await _db.runTransaction((tx) async {
      final newRef = _db.collection('usernames').doc(newLower);
      final snap = await tx.get(newRef);
      if (snap.exists &&
          snap.data()?['uid'] != uid) {
        throw Exception('Username "$newUsername" is already taken.');
      }
      if (oldUsernameLower.isNotEmpty && oldUsernameLower != newLower) {
        tx.delete(_db.collection('usernames').doc(oldUsernameLower));
      }
      tx.set(newRef, {'uid': uid});
      tx.update(_db.collection('users').doc(uid), {'username': newUsername});
    });
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
          'totalHeatingUp': FieldValue.increment(player.heatingUp),
          'totalBounceAttempts': FieldValue.increment(player.bounceAttempts),
          'totalBounceMakes': FieldValue.increment(player.bounceMakes),
          'totalIslandAttempts': FieldValue.increment(player.islandAttempts),
          'totalIslandMakes': FieldValue.increment(player.islandMakes),
          'totalDeathCupHits': FieldValue.increment(player.deathCupHits),
          'lastGameAt': FieldValue.serverTimestamp(),
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

  /// Prefix-searches users by lowercase username.
  /// Returns up to 10 results, excluding [excludeId] (the searching user).
  Future<List<User>> searchUsers(String query,
      {required String excludeId}) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();
    try {
      final snapshot = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: lower)
          .where('usernameLower', isLessThan: '$lower\uf8ff')
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'id': doc.id}))
          .where((u) => u.id != excludeId)
          .toList();
    } catch (e) {
      AppLogger.error('Error searching users', e);
      rethrow;
    }
  }

  // ----- FCM token management -----

  /// Adds [token] to the user's `fcmTokens` array in Firestore (arrayUnion —
  /// safe to call multiple times; duplicates are ignored).
  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      AppLogger.warning('saveFcmToken failed for $userId: $e');
    }
  }

  /// Removes [token] from the user's `fcmTokens` array (arrayRemove).
  /// Called on logout or when FCM reports the token as invalid.
  Future<void> removeFcmToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      AppLogger.warning('removeFcmToken failed for $userId: $e');
    }
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
      totalHeatingUp: oldUser.totalHeatingUp + player.heatingUp,
      totalBounceAttempts: oldUser.totalBounceAttempts + player.bounceAttempts,
      totalBounceMakes: oldUser.totalBounceMakes + player.bounceMakes,
      totalIslandAttempts: oldUser.totalIslandAttempts + player.islandAttempts,
      totalIslandMakes: oldUser.totalIslandMakes + player.islandMakes,
      totalDeathCupHits: oldUser.totalDeathCupHits + player.deathCupHits,
    );
  }
}
