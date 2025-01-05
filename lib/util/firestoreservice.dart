import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/invitation.dart';

/// Provides methods to interact with Firestore for users, games, stats, etc.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update a user in Firestore.
  Future<void> addUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  /// Update an existing user in Firestore.
  Future<void> updateUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Fetch a user by ID from Firestore.
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return _userFromFirestore(doc);
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  /// Remove a user from Firestore.
  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Maps a DocumentSnapshot into a User.
  User _userFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  //region ----- Games Logic -----

  /// Saves a new completed game to Firestore, updates user stats for each player.
  Future<List<User>> saveGame({
    required List<Player> team1,
    required List<Player> team2,
    required String winner,
  }) async {
    final updatedUsers = <User>[];
    try {
      // 1) Create participants list
      final participants = <dynamic>{
        ...team1.map((p) => p.user?.id ?? ''),
        ...team2.map((p) => p.user?.id ?? ''),
      }.toList(); // remove duplicates

      // 2) Add the game doc
      await _db.collection('games').add({
        'team1': team1.map((player) => player.toJson()).toList(),
        'team2': team2.map((player) => player.toJson()).toList(),
        'winner': winner,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': participants,
      });

      // 3) Update each player's user stats
      for (final player in [...team1, ...team2]) {
        if (player.user == null) continue;
        final isWinner = (winner == 'Team 1' && team1.contains(player)) ||
            (winner == 'Team 2' && team2.contains(player));

        final updatedUser = _mapPlayerToUser(player, isWinner);
        await updateUser(updatedUser);
        updatedUsers.add(updatedUser);
      }
    } catch (e) {
      print('Error saving game: $e');
    }
    return updatedUsers;
  }

  /// Helper to copy relevant stats from Player => existing User, incrementing them.
  User _mapPlayerToUser(Player player, bool isWinner) {
    final oldUser = player.user!;
    // increment stats
    final newTotalScore = oldUser.totalScore + player.score;
    final newTotalMisses = oldUser.totalMisses + player.misses;
    final newTotalAirballs = oldUser.totalAirballs + player.airballs;
    final newTotalThrows = oldUser.totalThrows + player.throws;
    final newOnFire = oldUser.onFire + player.onFire;
    final newDefended = oldUser.defended + player.defended;
    final newHitLastCup = oldUser.hitLastCup + (player.lastCupHit ? 1 : 0);
    final newCupsHit = [...oldUser.cupsHit, ...player.cupsHit];
    final newWins = oldUser.wins + (isWinner ? 1 : 0);
    final newLosses = oldUser.losses + (isWinner ? 0 : 1);

    return oldUser.copyWith(
      totalScore: newTotalScore,
      totalMisses: newTotalMisses,
      totalAirballs: newTotalAirballs,
      totalThrows: newTotalThrows,
      onFire: newOnFire,
      defended: newDefended,
      hitLastCup: newHitLastCup,
      cupsHit: newCupsHit,
      wins: newWins,
      losses: newLosses,
    );
  }

  /// Retrieve games from Firestore for the current user (descending timestamp).
  Future<List<GameStatistics>> retrieveGames() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return GameStatistics.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      print('Error retrieving games: $e');
      return [];
    }
  }

  /// Retrieve (date, player's stats) for the current user across all games.
  Future<List<UserStatsInGame>> retrieveUserStatsWithDate() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final allGames = snapshot.docs.map((doc) {
        return GameStatistics.fromFirestore(doc.data());
      }).toList();

      final userStatsList = <UserStatsInGame>[];

      for (final game in allGames) {
        final allPlayersInGame = [...game.team1Players, ...game.team2Players];
        final matchingPlayer = allPlayersInGame.firstWhere(
          (p) => p.user?.id == currentUser.uid,
          orElse: () => Player(name: 'notFound'),
        );

        if (matchingPlayer.name != 'notFound') {
          userStatsList.add(
            UserStatsInGame(
              date: game.date, // from your GameStatistics
              player: matchingPlayer,
            ),
          );
        }
      }

      return userStatsList;
    } catch (e) {
      print('Error retrieving user stats: $e');
      return [];
    }
  }
  //endregion

  //region ----- Friend Functions -----

  /// Returns a list of this user's friends
  Future<List<User>> getFriends(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>;
      final friendIds = List<String>.from(data['friends'] ?? []);

      final friends = <User>[];
      for (final friendId in friendIds) {
        final friendDoc = await _db.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          friends.add(_userFromFirestore(friendDoc));
        }
      }
      return friends;
    } catch (e) {
      print('Error fetching friends: $e');
      rethrow;
    }
  }

  /// Add friend to each other's friend list
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
      print('Error adding friend: $e');
      rethrow;
    }
  }
  //endregion

  //region ----- Invitation Functions -----
  Future<String> sendGameInvitation({
    required String fromUserId,
    required String toUserId,
    required int teamNumber,
    required int playerIndex,
  }) async {
    final docRef = await _db.collection('invitations').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'teamNumber': teamNumber,
      'playerIndex': playerIndex,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateInvitationStatus(
      String invitationId, String newStatus) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': newStatus,
    });
  }

  Future<void> deleteGameInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).delete();
  }

  Future<List<Invitation>> getGameInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Invitation(
        id: doc.id,
        fromUserId: data['fromUserId'],
        toUserId: data['toUserId'],
        teamNumber: data['teamNumber'],
        playerIndex: data['playerIndex'],
        status: data['status'],
        createdAt: data['createdAt'],
      );
    }).toList();
  }

  Future<List<Invitation>> getAllInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Invitation(
        id: doc.id,
        fromUserId: data['fromUserId'],
        toUserId: data['toUserId'],
        teamNumber: data['teamNumber'],
        playerIndex: data['playerIndex'],
        status: data['status'],
        createdAt: data['createdAt'],
      );
    }).toList();
  }
  //endregion
}
