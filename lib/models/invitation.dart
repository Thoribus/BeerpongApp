import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  final String id;
  final String fromUserId;
  final String toUserId;
  final int teamNumber;
  final int playerIndex;
  final String status;
  final Timestamp createdAt;
  final String gameId;

  Invitation({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.teamNumber,
    required this.playerIndex,
    required this.status,
    required this.createdAt,
    required this.gameId,
  });

  factory Invitation.fromMap(Map<String, dynamic> data, String documentId) {
    final fromUserId = data['fromUserId'];
    final toUserId = data['toUserId'];
    final teamNumber = data['teamNumber'];
    final playerIndex = data['playerIndex'];
    final status = data['status'];
    final createdAt = data['createdAt'];
    final gameId = data['gameId'];

    return Invitation(
      id: documentId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      teamNumber: teamNumber,
      playerIndex: playerIndex,
      status: status,
      createdAt: createdAt,
      gameId: gameId,
    );
  }
}