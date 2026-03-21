import 'dart:async';

import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Holds all lobby state and business logic for [GameModeDetailsScreen].
/// The screen creates this in [initState], adds a listener that calls
/// [setState], and accesses all state via [_ctrl.field].
class GameLobbyController extends ChangeNotifier {
  // ----- Game / Lobby State -----
  String? gameId;
  final List<Player> playersBlue = [];
  final List<Player> playersRed = [];

  final Map<int, String> blueInvitationDocIds = {};
  final Map<int, String> blueInvitationStatuses = {};
  final Map<int, User> blueFriendMap = {};
  final Map<int, String> redInvitationDocIds = {};
  final Map<int, String> redInvitationStatuses = {};
  final Map<int, User> redFriendMap = {};

  final List<String> acceptedInvites = [];
  late Map<String, bool> selectedRules;

  String startingTeam = 'Team Blue';
  bool started = false;

  // ----- Stream Subscriptions -----
  final List<StreamSubscription<dynamic>> _subs = [];

  // ----- Callbacks for UI operations -----
  void Function(String message)? onShowMessage;
  VoidCallback? onInvitationDeclined;

  GameLobbyController({required Map<String, bool> initialRules}) {
    selectedRules = Map<String, bool>.from(initialRules);
  }

  // ----- Init -----

  Future<void> createGameDoc() async {
    final emptyBlue = Team(
      color: Colors.blue,
      players: [],
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
    );
    final emptyRed = Team(
      color: Colors.red,
      players: [],
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
    );
    final docId = await FirestoreService.instance.createEmptyGameDoc(
      team1: emptyBlue,
      team2: emptyRed,
    );
    gameId = docId;
    notifyListeners();
  }

  // ----- Lifecycle cleanup -----

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    for (final docId in blueInvitationDocIds.values) {
      if (docId.isNotEmpty) {
        FirestoreService.instance.deleteGameInvitation(docId);
      }
    }
    for (final docId in redInvitationDocIds.values) {
      if (docId.isNotEmpty) {
        FirestoreService.instance.deleteGameInvitation(docId);
      }
    }
    if (!started && gameId != null) {
      FirestoreService.instance.deleteGameDoc(gameId!);
    }
    super.dispose();
  }

  // ----- Player management -----

  void addPlayer(bool isBlue) {
    final list = isBlue ? playersBlue : playersRed;
    list.add(Player(name: '', user: null));
    notifyListeners();
    unawaited(updateGameDoc());
  }

  void removePlayer(bool isBlue, int rowIndex) {
    final players = isBlue ? playersBlue : playersRed;
    final docIds = isBlue ? blueInvitationDocIds : redInvitationDocIds;
    final statuses = isBlue ? blueInvitationStatuses : redInvitationStatuses;
    final docId = docIds[rowIndex];
    if (docId != null && docId.isNotEmpty) {
      FirestoreService.instance.deleteGameInvitation(docId);
      docIds.remove(rowIndex);
      statuses.remove(rowIndex);
    }
    players.removeAt(rowIndex);
    notifyListeners();
    unawaited(updateGameDoc());
  }

  void updatePlayerName(bool isBlue, int rowIndex, String name) {
    final players = isBlue ? playersBlue : playersRed;
    players[rowIndex] = players[rowIndex].copyWithName(name);
    notifyListeners();
    unawaited(updateGameDoc());
  }

  /// Called when the current user picks themselves for a slot.
  Future<void> selectSelf(bool isBlue, int rowIndex, User user) async {
    final players = isBlue ? playersBlue : playersRed;
    players[rowIndex] = players[rowIndex].copyWithName(user.username);
    players[rowIndex] = players[rowIndex].copyWithUser(user);
    notifyListeners();
    await updateGameDoc();
  }

  // ----- Invitation -----

  Future<void> sendInvitation({
    required bool isBlue,
    required int rowIndex,
    required String fromUserId,
    required String fromUsername,
    required User selected,
  }) async {
    final players = isBlue ? playersBlue : playersRed;
    players[rowIndex] = players[rowIndex].copyWithName(selected.username);
    players[rowIndex] = players[rowIndex].copyWithUser(selected);
    notifyListeners();

    final docId = await FirestoreService.instance.sendGameInvitation(
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      toUserId: selected.id,
      teamNumber: isBlue ? 1 : 2,
      playerIndex: rowIndex,
      gameId: gameId!,
    );

    if (isBlue) {
      blueInvitationDocIds[rowIndex] = docId;
      blueInvitationStatuses[rowIndex] = 'pending';
      blueFriendMap[rowIndex] = selected;
    } else {
      redInvitationDocIds[rowIndex] = docId;
      redInvitationStatuses[rowIndex] = 'pending';
      redFriendMap[rowIndex] = selected;
    }
    notifyListeners();
    _listenToInvitationStatus(isBlue, rowIndex, docId);
    await updateGameDoc();
  }

  void _listenToInvitationStatus(bool isBlue, int rowIndex, String docId) {
    final sub = FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';

      if (status == 'accepted') {
        if (!acceptedInvites.contains(docId)) acceptedInvites.add(docId);
        if (isBlue) {
          final friend = blueFriendMap[rowIndex];
          if (friend != null) {
            playersBlue[rowIndex] = playersBlue[rowIndex].copyWithName(friend.username);
            playersBlue[rowIndex] = playersBlue[rowIndex].copyWithUser(friend);
          }
          blueInvitationStatuses.remove(rowIndex);
        } else {
          final friend = redFriendMap[rowIndex];
          if (friend != null) {
            playersRed[rowIndex] = playersRed[rowIndex].copyWithName(friend.username);
            playersRed[rowIndex] = playersRed[rowIndex].copyWithUser(friend);
          }
          redInvitationStatuses.remove(rowIndex);
        }
        notifyListeners();
        unawaited(updateGameDoc());
      } else if (status == 'declined') {
        unawaited(FirestoreService.instance.deleteGameInvitation(docId));
        if (isBlue) {
          blueInvitationDocIds.remove(rowIndex);
          blueInvitationStatuses.remove(rowIndex);
          playersBlue[rowIndex] = playersBlue[rowIndex].copyWithName('');
          playersBlue[rowIndex] = playersBlue[rowIndex].copyWithUser(null);
        } else {
          redInvitationDocIds.remove(rowIndex);
          redInvitationStatuses.remove(rowIndex);
          playersRed[rowIndex] = playersRed[rowIndex].copyWithName('');
          playersRed[rowIndex] = playersRed[rowIndex].copyWithUser(null);
        }
        notifyListeners();
        unawaited(updateGameDoc());
        onInvitationDeclined?.call();
      } else if (status == 'pending') {
        if (isBlue) {
          blueInvitationStatuses[rowIndex] = 'pending';
        } else {
          redInvitationStatuses[rowIndex] = 'pending';
        }
        notifyListeners();
        unawaited(updateGameDoc());
      }
    });
    _subs.add(sub);
  }

  Future<void> cancelInvitation(bool isBlue, int rowIndex) async {
    final docId =
        isBlue ? blueInvitationDocIds[rowIndex] : redInvitationDocIds[rowIndex];
    if (docId == null || docId.isEmpty) return;
    await FirestoreService.instance.deleteGameInvitation(docId);
    if (isBlue) {
      blueInvitationDocIds.remove(rowIndex);
      blueInvitationStatuses.remove(rowIndex);
      playersBlue[rowIndex] = playersBlue[rowIndex].copyWithName('');
      playersBlue[rowIndex] = playersBlue[rowIndex].copyWithUser(null);
    } else {
      redInvitationDocIds.remove(rowIndex);
      redInvitationStatuses.remove(rowIndex);
      playersRed[rowIndex] = playersRed[rowIndex].copyWithName('');
      playersRed[rowIndex] = playersRed[rowIndex].copyWithUser(null);
    }
    notifyListeners();
    await updateGameDoc();
    onShowMessage?.call('Invitation canceled');
  }

  // ----- Rules -----

  void toggleRule(String ruleName, bool value) {
    selectedRules[ruleName] = value;
    notifyListeners();
  }

  // ----- Game start -----

  bool canStartGame() {
    if (playersBlue.isEmpty || playersRed.isEmpty) return false;
    if (playersBlue.any((p) => p.name.trim().isEmpty)) return false;
    if (playersRed.any((p) => p.name.trim().isEmpty)) return false;
    if (blueInvitationStatuses.values.contains('pending')) return false;
    if (redInvitationStatuses.values.contains('pending')) return false;
    return true;
  }

  Future<void> startGame(String chosenTeam, {String? hostUserId}) async {
    started = true;
    startingTeam = chosenTeam;
    notifyListeners();
    await updateGameDoc();

    final gid = gameId;
    if (gid != null) {
      final uids = <String>[
        if (hostUserId != null) hostUserId,
        ...blueFriendMap.values.map((u) => u.id),
        ...redFriendMap.values.map((u) => u.id),
      ];
      for (final uid in uids) {
        unawaited(FirestoreService.instance.setActiveGameId(uid, gid));
      }
    }
  }

  // ----- Firestore sync -----

  Future<void> updateGameDoc() async {
    if (gameId == null) return;
    final teamBlue = Team(
      color: Colors.blue,
      players: playersBlue,
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
    );
    final teamRed = Team(
      color: Colors.red,
      players: playersRed,
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
    );
    await FirestoreService.instance.updateGameDoc(
      gameId!,
      team1: teamBlue,
      team2: teamRed,
      rules: selectedRules.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      startingTeam: startingTeam,
      invitations: acceptedInvites,
      started: started,
      timestamp: true,
      tournamentId: '',
    );
  }
}
