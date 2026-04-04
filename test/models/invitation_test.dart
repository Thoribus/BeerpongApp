import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/invitation.dart';

Timestamp _ts(DateTime dt) => Timestamp.fromDate(dt);

Invitation _makeInvitation({
  InvitationStatus status = InvitationStatus.pending,
  Timestamp? expiresAt,
}) =>
    Invitation(
      id: 'inv-1',
      fromUserId: 'user-a',
      fromUsername: 'Alice',
      toUserId: 'user-b',
      status: status,
      gameId: 'game-1',
      teamNumber: 1,
      playerIndex: 0,
      createdAt: _ts(DateTime.utc(2026, 1, 1)),
      expiresAt: expiresAt,
    );

void main() {
  group('InvitationStatus.fromString', () {
    test('parses each known status', () {
      expect(InvitationStatus.fromString('pending'), InvitationStatus.pending);
      expect(InvitationStatus.fromString('accepted'), InvitationStatus.accepted);
      expect(InvitationStatus.fromString('declined'), InvitationStatus.declined);
      expect(InvitationStatus.fromString('cancelled'), InvitationStatus.cancelled);
      expect(InvitationStatus.fromString('expired'), InvitationStatus.expired);
    });

    test('defaults to pending for unknown string', () {
      expect(InvitationStatus.fromString('unknown'), InvitationStatus.pending);
    });

    test('defaults to pending for null', () {
      expect(InvitationStatus.fromString(null), InvitationStatus.pending);
    });
  });

  group('GameType.fromString', () {
    test('parses regular and tournament types', () {
      expect(GameType.fromString('regular'), GameType.regular);
      expect(GameType.fromString('tournament'), GameType.tournament);
    });

    test('defaults to regular for unknown string', () {
      expect(GameType.fromString('invalid'), GameType.regular);
    });

    test('defaults to regular for null', () {
      expect(GameType.fromString(null), GameType.regular);
    });
  });

  group('Invitation.isExpired', () {
    test('returns false when expiresAt is null', () {
      final inv = _makeInvitation();
      expect(inv.isExpired, isFalse);
    });

    test('returns false for a future expiry', () {
      final inv = _makeInvitation(
        expiresAt: _ts(DateTime.now().add(const Duration(hours: 1))),
      );
      expect(inv.isExpired, isFalse);
    });

    test('returns true for a past expiry', () {
      final inv = _makeInvitation(
        expiresAt: _ts(DateTime.now().subtract(const Duration(hours: 1))),
      );
      expect(inv.isExpired, isTrue);
    });
  });

  group('Invitation.toMap / fromMap round-trip', () {
    test('preserves core fields', () {
      final inv = _makeInvitation(status: InvitationStatus.accepted);
      final map = inv.toMap();
      final restored = Invitation.fromMap(map, 'inv-1');

      expect(restored.id, 'inv-1');
      expect(restored.fromUserId, 'user-a');
      expect(restored.fromUsername, 'Alice');
      expect(restored.toUserId, 'user-b');
      expect(restored.status, InvitationStatus.accepted);
      expect(restored.gameId, 'game-1');
      expect(restored.teamNumber, 1);
      expect(restored.playerIndex, 0);
    });

    test('preserves gameType', () {
      final inv = Invitation(
        id: 'inv-2',
        fromUserId: 'u1',
        toUserId: 'u2',
        status: InvitationStatus.pending,
        gameId: 'g1',
        teamNumber: 2,
        playerIndex: 1,
        createdAt: _ts(DateTime.utc(2026, 1, 1)),
        gameType: GameType.tournament,
        tournamentId: 'tournament-1',
      );
      final map = inv.toMap();
      final restored = Invitation.fromMap(map, 'inv-2');

      expect(restored.gameType, GameType.tournament);
      expect(restored.tournamentId, 'tournament-1');
    });

    test('fromMap defaults teamNumber and playerIndex to 0 when absent', () {
      final map = <String, dynamic>{
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'status': 'pending',
        'gameId': 'g1',
        'createdAt': _ts(DateTime.utc(2026, 1, 1)),
      };
      final inv = Invitation.fromMap(map, 'inv-3');
      expect(inv.teamNumber, 0);
      expect(inv.playerIndex, 0);
    });

    test('fromMap with null status defaults to pending', () {
      final map = <String, dynamic>{
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'gameId': 'g1',
        'teamNumber': 1,
        'playerIndex': 0,
        'createdAt': _ts(DateTime.utc(2026, 1, 1)),
      };
      final inv = Invitation.fromMap(map, 'inv-4');
      expect(inv.status, InvitationStatus.pending);
    });

    test('expiresAt is null when not in map', () {
      final map = <String, dynamic>{
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'status': 'pending',
        'gameId': 'g1',
        'teamNumber': 0,
        'playerIndex': 0,
        'createdAt': _ts(DateTime.utc(2026, 1, 1)),
      };
      final inv = Invitation.fromMap(map, 'inv-5');
      expect(inv.expiresAt, isNull);
    });
  });
}
