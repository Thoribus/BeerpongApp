import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  static InvitationStatus fromString(String? value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

enum GameType {
  regular,
  tournament;

  static GameType fromString(String? value) {
    return GameType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameType.regular,
    );
  }
}

class Invitation {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String toUserId;
  final InvitationStatus status;
  final String gameId;
  final String tournamentId;
  final GameType gameType;
  final int teamNumber;
  final int playerIndex;
  final Timestamp createdAt;
  final Timestamp? expiresAt;

  Invitation({
    required this.id,
    required this.fromUserId,
    this.fromUsername = '',
    required this.toUserId,
    required this.status,
    required this.gameId,
    this.tournamentId = '',
    this.gameType = GameType.regular,
    required this.teamNumber,
    required this.playerIndex,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.toDate().isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'toUserId': toUserId,
      'status': status.name,
      'gameId': gameId,
      'tournamentId': tournamentId,
      'gameType': gameType.name,
      'teamNumber': teamNumber,
      'playerIndex': playerIndex,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory Invitation.fromMap(Map<String, dynamic> data, String documentId) {
    return Invitation(
      id: documentId,
      fromUserId: data['fromUserId'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      toUserId: data['toUserId'] ?? '',
      status: InvitationStatus.fromString(data['status']),
      gameId: data['gameId'] ?? '',
      tournamentId: data['tournamentId'] ?? '',
      gameType: GameType.fromString(data['gameType']),
      teamNumber: (data['teamNumber'] as num?)?.toInt() ?? 0,
      playerIndex: (data['playerIndex'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: data['expiresAt'] as Timestamp?,
    );
  }

  factory Invitation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Invitation.fromMap(doc.data()!, doc.id);
  }
}
