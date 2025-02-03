import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Create an empty "games" doc with default or placeholder fields
  Future<String> createEmptyGameDoc({
    required Team team1,
    required Team team2,
  }) async {
    final docRef = await _db.collection('games').add({
      'timestamp': FieldValue.serverTimestamp(),
      'winner': '',
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'participants': [
        // Maybe gather user IDs from team1+team2 if they're actual accounts
        ...team1.players.where((p) => p.user != null).map((p) => p.user!.id),
        ...team2.players.where((p) => p.user != null).map((p) => p.user!.id),
      ],
      'invitations': [],
      'specialRules': [],
      'gameMode': 'Single Game',
      'started': false,
      'startingTeam': 'Team Blue',
      'events': [],
    });
    return docRef.id; // Return the new document ID
  }

  // Update the game doc with new team arrays or other fields
  Future<void> updateGameDoc(
    String gameId, {
    Team? team1,
    Team? team2,
    String? winner,
    List<String>? invitations,
    List<String>? rules,
    String? gameMode,
    bool? started,
    String? startingTeam,
    bool? timestamp,
  }) async {
    // 1) Build a map for the fields you actually want to update
    final Map<String, dynamic> updates = {};

    // If these fields are non-null, add them to the map:
    if (team1 != null) {
      updates['team1'] = team1.toJson();
      // If your logic always wants to recalc participants from team1/team2, do it conditionally, etc.
    }
    if (team2 != null) {
      updates['team2'] = team2.toJson();
    }
    if (winner != null) {
      updates['winner'] = winner;
    }
    if (invitations != null) {
      updates['invitations'] = invitations;
    }
    if (rules != null) {
      updates['specialRules'] = rules;
    }
    if (gameMode != null) {
      updates['gameMode'] = gameMode;
    }
    if (started != null) {
      updates['started'] = started;
    }
    if (startingTeam != null) {
      updates['startingTeam'] = startingTeam;
    }
    if (timestamp == true) {
      updates['timestamp'] = FieldValue.serverTimestamp();
    }

    // Optionally, recalc participants if you do want them always updated
    // e.g. if team1 or team2 was given, re-derive participants from them
    if (team1 != null || team2 != null) {
      final participants = <String>[];
      if (team1 != null) {
        participants.addAll(
          team1.players.where((p) => p.user != null).map((p) => p.user!.id),
        );
      }
      if (team2 != null) {
        participants.addAll(
          team2.players.where((p) => p.user != null).map((p) => p.user!.id),
        );
      }
      updates['participants'] = participants;
    }

    // 2) If there's nothing to update, just return
    if (updates.isEmpty) {
      return;
    }

    // 3) Perform the partial update
    await _db.collection('games').doc(gameId).update(updates);
  }

  /// Returns a stream of game document snapshots
  Stream<DocumentSnapshot> getGameDocStream(String gameId) {
    return _db.collection('games').doc(gameId).snapshots();
  }

  // Delete the game doc if user leaves
  Future<void> deleteGameDoc(String gameId) async {
    await _db.collection('games').doc(gameId).delete();
  }

  /// Helper to copy relevant stats from Player => existing User, incrementing them.
  static User mapPlayerToUser(Player player) {
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
    final newWins = oldUser.wins + (player.isWinner ? 1 : 0);
    final newLosses = oldUser.losses + (player.isWinner ? 0 : 1);

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

  Future<Map<String, dynamic>?> retrieveGameById(String gameId) async {
    try {
      final doc = await _db.collection('games').doc(gameId).get();
      if (!doc.exists) return {};
      return doc.data();
    } catch (e) {
      print('Error getting game: $e');
      rethrow;
    }
  }

  /// Retrieve games from Firestore for the current user (descending timestamp).
  Future<List<GameStatistics>> retrieveGames(User user) async {
    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.id)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return GameStatistics.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('Error retrieving games: $e');
      return [];
    }
  }

  /// Retrieve (date, player's stats) for the current user across all games.
  Future<List<UserStatsInGame>> retrieveUserStatsWithDate(User user) async {
    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.id)
          .orderBy('timestamp', descending: true)
          .get();

      final allGames = snapshot.docs.map((doc) {
        return GameStatistics.fromFirestore(doc.id, doc.data());
      }).toList();

      final userStatsList = <UserStatsInGame>[];

      for (final game in allGames) {
        final allPlayersInGame = [...game.team1Players, ...game.team2Players];
        final matchingPlayer = allPlayersInGame.firstWhere(
          (p) => p.user?.id == user.id,
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

  //region ----- Event Functions -----
  Future<String> addEvent(String gameId, String eventType, Team team, Player? player) async {
    try {
      final eventsRef = FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .collection('events');

      final docRef = eventsRef.doc();

      await docRef.set({
        'eventType': eventType,
        'team': team.color.value.toString(),
        'player': player?.name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  Future<List<GameEvent>> getEvents(String gameId) async {
    try {
      final snapshot = await _db
          .collection('games')
          .doc(gameId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GameEvent.fromJson({
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String gameId, String eventId) async {
    try {
      await _db
          .collection('games')
          .doc(gameId)
          .collection('events')
          .doc(eventId)
          .delete();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
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
    required String gameId,
  }) async {
    final docRef = await _db.collection('invitations').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'teamNumber': teamNumber,
      'playerIndex': playerIndex,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'gameId': gameId,
    });
    return docRef.id;
  }

  Future<void> updateInvitationStatus(
      String invitationId, String newStatus) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': newStatus,
    });
  }

  Future<void> updateInvitationGameId(
      String invitationId, String gameId) async {
    await _db.collection('invitations').doc(invitationId).update({
      'gameId': gameId,
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
        gameId: data['gameId'],
      );
    }).toList();
  }

  Future<List<Invitation>> getGameInvitationsByGameId(String gameId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('gameId', isEqualTo: gameId)
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
        gameId: data['gameId'],
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
        gameId: data['gameId'],
      );
    }).toList();
  }

  getLastGame(String id) {}
  //endregion
}
