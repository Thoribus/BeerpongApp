import 'dart:async';
import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TournamentLobbyController extends ChangeNotifier {
  static const List<Color> _teamColors = [
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.indigo,
  ];

  final List<Player> players = [];
  final Map<int, String> invitationDocIds = {};
  final Map<int, String> invitationStatuses = {};
  final Map<int, User> friendMap = {};
  final List<String> acceptedInvites = [];
  final List<StreamSubscription<dynamic>> _subs = [];
  late Map<String, bool> selectedRules;

  void Function(String message)? onShowMessage;
  VoidCallback? onInvitationDeclined;

  TournamentLobbyController({required Map<String, bool> initialRules}) {
    selectedRules = Map<String, bool>.from(initialRules);
  }

  void addPlayer() {
    players.add(Player(name: '', user: null));
    notifyListeners();
  }

  void removePlayer(int rowIndex) {
    final docId = invitationDocIds[rowIndex];
    if (docId != null && docId.isNotEmpty) {
      FirestoreService.instance.deleteGameInvitation(docId);
      invitationDocIds.remove(rowIndex);
      invitationStatuses.remove(rowIndex);
    }
    players.removeAt(rowIndex);
    notifyListeners();
  }

  void updatePlayerName(int rowIndex, String name) {
    players[rowIndex] = players[rowIndex].copyWithName(name);
    notifyListeners();
  }

  void selectPlayer(int rowIndex, User user) {
    players[rowIndex] = players[rowIndex].copyWithName(user.username);
    players[rowIndex] = players[rowIndex].copyWithUser(user);
    notifyListeners();
  }

  Future<void> sendInvitation(
      int rowIndex, String fromUserId, User selected) async {
    players[rowIndex] = players[rowIndex].copyWithName(selected.username);
    players[rowIndex] = players[rowIndex].copyWithUser(selected);

    final docId = await FirestoreService.instance.sendGameInvitation(
      fromUserId: fromUserId,
      toUserId: selected.id,
      teamNumber: 1,
      playerIndex: rowIndex,
      gameId: '',
    );

    invitationDocIds[rowIndex] = docId;
    invitationStatuses[rowIndex] = 'pending';
    friendMap[rowIndex] = selected;
    _listenToInvitationStatus(rowIndex, docId);
    notifyListeners();
  }

  void _listenToInvitationStatus(int rowIndex, String docId) {
    final sub = FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';
      if (status == 'accepted') {
        if (!acceptedInvites.contains(docId)) {
          acceptedInvites.add(docId);
        }
        final friend = friendMap[rowIndex];
        if (friend != null) {
          players[rowIndex] = players[rowIndex].copyWithName(friend.username);
          players[rowIndex] = players[rowIndex].copyWithUser(friend);
        }
        invitationStatuses.remove(rowIndex);
        notifyListeners();
      } else if (status == 'declined') {
        unawaited(FirestoreService.instance.deleteGameInvitation(docId));
        invitationDocIds.remove(rowIndex);
        invitationStatuses.remove(rowIndex);
        players[rowIndex] = players[rowIndex].copyWithName('');
        players[rowIndex] = players[rowIndex].copyWithUser(null);
        notifyListeners();
        onInvitationDeclined?.call();
      } else if (status == 'pending') {
        invitationStatuses[rowIndex] = 'pending';
        notifyListeners();
      }
    });
    _subs.add(sub);
  }

  Future<void> cancelInvitation(int rowIndex) async {
    final docId = invitationDocIds[rowIndex];
    if (docId == null || docId.isEmpty) return;
    await FirestoreService.instance.deleteGameInvitation(docId);
    invitationDocIds.remove(rowIndex);
    invitationStatuses.remove(rowIndex);
    players[rowIndex] = players[rowIndex].copyWithName('');
    players[rowIndex] = players[rowIndex].copyWithUser(null);
    notifyListeners();
    onShowMessage?.call('Invitation canceled');
  }

  void toggleRule(String ruleName, bool value) {
    selectedRules[ruleName] = value;
    notifyListeners();
  }

  bool canStartTournament() {
    if (players.length <= 1) return false;
    if (players.any((p) => p.name.trim().isEmpty)) return false;
    if (invitationStatuses.values.contains('pending')) return false;
    return true;
  }

  Future<Tournament> createTournament(String name) async {
    final List<Team> teams = players.asMap().entries.map((entry) {
      final i = entry.key;
      final player = entry.value;
      final color = _teamColors[i % _teamColors.length];
      return Team(
        color: color,
        players: [player],
        cups: List.generate(10, (index) => Cup(index: index, color: color)),
      );
    }).toList();

    final List<TournamentMatch> matches =
        generateRoundRobinMatches(teams, selectedRules, acceptedInvites);

    final String tournamentId =
        FirebaseFirestore.instance.collection('tournaments').doc().id;

    final Tournament tournament = Tournament(
      id: tournamentId,
      name: name,
      teams: teams,
      matches: matches,
      started: true,
      finished: false,
    );

    await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .set(tournament.toJson());

    return tournament;
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    for (final docId in invitationDocIds.values) {
      if (docId.isNotEmpty) {
        unawaited(FirestoreService.instance.deleteGameInvitation(docId));
      }
    }
    super.dispose();
  }
}
