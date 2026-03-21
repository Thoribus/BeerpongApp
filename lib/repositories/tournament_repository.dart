import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentRepository {
  TournamentRepository._();
  static final TournamentRepository instance = TournamentRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createTournament(Tournament tournament) async {
    try {
      final docRef =
          await _db.collection('tournaments').add(tournament.toJson());
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating tournament', e);
      rethrow;
    }
  }

  Future<void> updateTournament(Tournament tournament) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournament.id)
          .update(tournament.toJson());
    } catch (e) {
      AppLogger.error('Error updating tournament', e);
      rethrow;
    }
  }

  Future<Tournament?> getTournament(String tournamentId) async {
    try {
      final doc =
          await _db.collection('tournaments').doc(tournamentId).get();
      if (!doc.exists) return null;
      final tournament = Tournament.fromJson({...doc.data()!, 'id': doc.id});
      // Load matches from sub-collection (authoritative source)
      final matches = await getTournamentMatches(tournamentId);
      return tournament.copyWith(matches: matches);
    } catch (e) {
      AppLogger.error('Error fetching tournament', e);
      rethrow;
    }
  }

  Future<void> deleteTournament(String tournamentId) async {
    try {
      final matches = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .get();
      final batch = _db.batch();
      for (final doc in matches.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('tournaments').doc(tournamentId));
      await batch.commit();
    } catch (e) {
      AppLogger.error('Error deleting tournament', e);
      rethrow;
    }
  }

  Future<List<Tournament>> getTournamentsForUser(String userId) async {
    try {
      final snapshot = await _db
          .collection('tournaments')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Tournament.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting tournaments for user', e);
      return [];
    }
  }

  Future<String> addMatchToTournament(
      String tournamentId, TournamentMatch match) async {
    try {
      final docRef = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .add(match.toJson());
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding match', e);
      rethrow;
    }
  }

  Future<void> updateTournamentMatch(
      String tournamentId, TournamentMatch match) async {
    try {
      await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(match.id)
          .update(match.toJson());
    } catch (e) {
      AppLogger.error('Error updating match', e);
      rethrow;
    }
  }

  Future<List<TournamentMatch>> getTournamentMatches(
      String tournamentId) async {
    try {
      final snapshot = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .orderBy('round')
          .get();
      return snapshot.docs
          .map((doc) =>
              TournamentMatch.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching matches', e);
      return [];
    }
  }

  Future<TournamentMatch?> getTournamentMatch(
      String tournamentId, String matchId) async {
    try {
      final doc = await _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .get();
      if (!doc.exists) return null;
      return TournamentMatch.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      AppLogger.error('Error fetching match', e);
      rethrow;
    }
  }
}
