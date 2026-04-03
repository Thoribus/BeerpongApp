import 'package:beerpongapp/models/invitation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationRepository {
  InvitationRepository._();
  static final InvitationRepository instance = InvitationRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a new pending invitation document.
  ///
  /// [fromUsername] is denormalized so Cloud Functions can build the
  /// notification payload without an extra user lookup.
  /// [tournamentId] is populated for tournament invites; [gameId] for regular.
  /// [expiresAt] is set to 1 hour from now — Cloud Functions expire stale docs.
  Future<String> sendGameInvitation({
    required String fromUserId,
    required String toUserId,
    required int teamNumber,
    required int playerIndex,
    required String gameId,
    String fromUsername = '',
    String tournamentId = '',
    String gameType = 'regular',
  }) async {
    final expiresAt = Timestamp.fromDate(
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    final docRef = await _db.collection('invitations').add({
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'toUserId': toUserId,
      'teamNumber': teamNumber,
      'playerIndex': playerIndex,
      'status': InvitationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'gameId': gameId,
      'tournamentId': tournamentId,
      'gameType': gameType,
    });
    return docRef.id;
  }

  Future<void> updateInvitationStatus(
      String invitationId, String newStatus) async {
    await _db
        .collection('invitations')
        .doc(invitationId)
        .update({'status': newStatus});
  }

  Future<void> updateInvitationGameId(
      String invitationId, String gameId) async {
    try {
      await _db
          .collection('invitations')
          .doc(invitationId)
          .update({'gameId': gameId});
    } on FirebaseException catch (e) {
      // Invitation was deleted (player kicked then re-invited) — safe to ignore.
      if (e.code == 'not-found') return;
      rethrow;
    }
  }

  Future<void> deleteGameInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).delete();
  }

  Invitation _invitationFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Invitation.fromDoc(doc);
  }

  /// One-shot fetch: pending invitations addressed to [userId].
  Future<List<Invitation>> getGameInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .get();
    return snapshot.docs.map(_invitationFromDoc).toList();
  }

  Future<List<Invitation>> getGameInvitationsByGameId(String gameId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('gameId', isEqualTo: gameId)
        .get();
    return snapshot.docs.map(_invitationFromDoc).toList();
  }

  /// One-shot fetch: all invitations (any status) addressed to [userId].
  Future<List<Invitation>> getAllInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .get();
    return snapshot.docs.map(_invitationFromDoc).toList();
  }

  /// Real-time stream of pending invitations addressed to [userId].
  /// Used by HomeScreen to keep the badge count live without polling.
  Stream<List<Invitation>> pendingInvitationsStream(String userId) {
    return _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map(_invitationFromDoc).toList());
  }
}
