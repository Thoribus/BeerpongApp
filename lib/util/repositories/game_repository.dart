import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameRepository {
  GameRepository._();
  static final GameRepository instance = GameRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        ...team1.players.where((p) => p.user != null).map((p) => p.user!.id),
        ...team2.players.where((p) => p.user != null).map((p) => p.user!.id),
      ],
      'invitations': [],
      'specialRules': [],
      'gameMode': 'Single Game',
      'started': false,
      'startingTeam': 'Team Blue',
      'events': [],
      'tournamentId': '',
    });
    return docRef.id;
  }

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
    String? tournamentId,
  }) async {
    final Map<String, dynamic> updates = {};

    if (team1 != null) updates['team1'] = team1.toJson();
    if (team2 != null) updates['team2'] = team2.toJson();
    if (winner != null) updates['winner'] = winner;
    if (invitations != null) updates['invitations'] = invitations;
    if (rules != null) updates['specialRules'] = rules;
    if (gameMode != null) updates['gameMode'] = gameMode;
    if (started != null) updates['started'] = started;
    if (startingTeam != null) updates['startingTeam'] = startingTeam;
    if (timestamp == true) updates['timestamp'] = FieldValue.serverTimestamp();
    if (tournamentId != null) updates['tournamentId'] = tournamentId;

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

    if (updates.isEmpty) return;
    await _db.collection('games').doc(gameId).update(updates);
  }

  Stream<DocumentSnapshot> getGameDocStream(String gameId) {
    return _db.collection('games').doc(gameId).snapshots();
  }

  Future<void> deleteGameDoc(String gameId) async {
    await _db.collection('games').doc(gameId).delete();
  }

  Future<Map<String, dynamic>?> retrieveGameById(String gameId) async {
    try {
      final doc = await _db.collection('games').doc(gameId).get();
      if (!doc.exists) return {};
      return doc.data();
    } catch (e) {
      AppLogger.error('Error getting game', e);
      rethrow;
    }
  }

  Future<List<GameStatistics>> retrieveGames(User user) async {
    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.id)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => GameStatistics.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('Error retrieving games', e);
      return [];
    }
  }

  Future<List<UserStatsInGame>> retrieveUserStatsWithDate(User user) async {
    try {
      final snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.id)
          .orderBy('timestamp', descending: true)
          .get();

      final allGames = snapshot.docs
          .map((doc) => GameStatistics.fromFirestore(doc.id, doc.data()))
          .toList();

      final userStatsList = <UserStatsInGame>[];
      for (final game in allGames) {
        final allPlayersInGame = [...game.team1Players, ...game.team2Players];
        final matchingPlayer = allPlayersInGame.firstWhere(
          (p) => p.user?.id == user.id,
          orElse: () => Player(name: 'notFound'),
        );
        if (matchingPlayer.name != 'notFound') {
          userStatsList.add(
            UserStatsInGame(date: game.date, player: matchingPlayer),
          );
        }
      }
      return userStatsList;
    } catch (e) {
      AppLogger.error('Error retrieving user stats', e);
      return [];
    }
  }

  Future<String> addEvent(
      String gameId, String eventType, Team team, Player? player) async {
    try {
      final eventsRef =
          _db.collection('games').doc(gameId).collection('events');
      final docRef = eventsRef.doc();
      await docRef.set({
        'eventType': eventType,
        'team': team.color.toARGB32().toString(),
        'player': player?.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding event', e);
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
        return GameEvent.fromJson({...doc.data()}, doc.id, gameId);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching events', e);
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
      AppLogger.error('Error deleting event', e);
      rethrow;
    }
  }
}
