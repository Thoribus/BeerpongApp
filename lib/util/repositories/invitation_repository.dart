import 'package:beerpongapp/models/invitation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationRepository {
  InvitationRepository._();
  static final InvitationRepository instance = InvitationRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _db
        .collection('invitations')
        .doc(invitationId)
        .update({'status': newStatus});
  }

  Future<void> updateInvitationGameId(
      String invitationId, String gameId) async {
    await _db
        .collection('invitations')
        .doc(invitationId)
        .update({'gameId': gameId});
  }

  Future<void> deleteGameInvitation(String invitationId) async {
    await _db.collection('invitations').doc(invitationId).delete();
  }

  Invitation _invitationFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
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
  }

  Future<List<Invitation>> getGameInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
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

  Future<List<Invitation>> getAllInvitations(String userId) async {
    final snapshot = await _db
        .collection('invitations')
        .where('toUserId', isEqualTo: userId)
        .get();
    return snapshot.docs.map(_invitationFromDoc).toList();
  }
}
