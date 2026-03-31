import 'dart:async';
import 'dart:math';

import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';

/// Holds all game state and business logic.
/// [GameScreen] creates this in [initState], adds a listener that calls
/// [setState], and accesses all state via [_ctrl.field].
class GameController extends ChangeNotifier {
  final UserProvider _userProvider;

  // ----- Game / Team / Player State -----
  late String id;
  late Map<String, bool> selectedRules;
  late List<String> invitations;
  late String tournamentId;

  late Team team1;
  late Team team2;
  late Team currentTeam;

  bool gameEnded = false;
  late bool isTeamOneTurn;
  String winner = '';
  int roundCount = 0;
  int cupsRemainingWinner = 0;

  bool islandShotActive = false;
  Player? currentIslandShooter;
  Color islandBackgroundColor = Colors.grey;

  bool bounceShotActive = false;
  Player? currentBounceShooter;

  // Gradient animation state used by the player-name cards.
  Alignment beginAlignment = Alignment.topLeft;
  Alignment endAlignment = Alignment.bottomRight;

  // ----- Undo / Event State -----
  final List<Map<String, dynamic>> _actionStack = [];
  final List<String> _events = [];

  GameController(this._userProvider);

  // ----- Load Game State -----

  Future<void> loadGameState({
    required String widgetId,
    required Team widgetTeam1,
    required Team widgetTeam2,
    required bool widgetStartingTeam,
    required List<String> widgetInvitations,
    required Map<String, bool> widgetSelectedRules,
    required String widgetTournamentId,
  }) async {
    final map = await GamePersistence.loadGameState();
    if (map == null) {
      id = widgetId;
      team1 = widgetTeam1;
      team2 = widgetTeam2;
      isTeamOneTurn = widgetStartingTeam;
      currentTeam = isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();
      invitations = widgetInvitations;
      selectedRules = widgetSelectedRules;
      tournamentId = widgetTournamentId;
      notifyListeners();
      return;
    }

    id = map['id'];
    team1 = Team.fromJson(map['team1']);
    team2 = Team.fromJson(map['team2']);
    isTeamOneTurn = map['isTeamOneTurn'] ?? false;
    islandShotActive = map['islandShotActive'] ?? false;
    invitations = List<String>.from(map['invitations']);
    selectedRules = Map<String, bool>.from(map['selectedRules']);
    tournamentId = map['tournamentId'] ?? '';
    currentTeam = isTeamOneTurn ? team1 : team2;
    currentTeam.currentPlayers = currentTeam.rotatePlayers();
    notifyListeners();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateIslandBackgroundColor());
  }

  Future<void> persistIfNotEnded() async {
    if (!gameEnded) {
      await GamePersistence.saveGameState(
        id: id,
        team1: team1,
        team2: team2,
        isTeamOneTurn: isTeamOneTurn,
        islandShotActive: islandShotActive,
        invitations: invitations,
        selectedRules: selectedRules,
        tournamentId: tournamentId,
      );
    }
  }

  // ----- Gradient Animation -----

  void toggleGradientDirection() {
    final temp = beginAlignment;
    beginAlignment = endAlignment;
    endAlignment = temp;
    notifyListeners();
  }

  // ----- Core Game Logic -----

  void handleCupHit(int index, BuildContext ctx) {
    final cup = currentTeam.cups.firstWhere((c) => c.index == index);
    if (cup.color == Colors.green) {
      _checkProximity(index);
    } else {
      cup.color = Colors.green;
      checkBallsBack(ctx);
      checkBitchCup(index, ctx);
    }
    notifyListeners();
  }

  /// Enters bounce-shot mode for [player]. The next cup tap will be treated
  /// as the bounced cup; a random bonus cup is also removed (counts as 2).
  void activateBounceShot(Player player) {
    currentBounceShooter = player;
    bounceShotActive = true;
    notifyListeners();
  }

  /// Cancels bounce-shot mode without recording anything.
  void cancelBounceShot() {
    bounceShotActive = false;
    currentBounceShooter = null;
    notifyListeners();
  }

  void _checkProximity(int index) {
    const double proximityThreshold = 100.0;
    int adjacentHits = 0;

    final targetCup = currentTeam.cups.firstWhere(
      (cup) => cup.index == index && cup.isVisible,
      orElse: () => Cup(index: -1, color: Colors.transparent),
    );
    if (targetCup.index == -1) return;

    for (final cup in currentTeam.cups) {
      if (cup.index == index || !cup.isVisible) continue;
      final renderBox1 =
          cup.key.currentContext?.findRenderObject() as RenderBox?;
      final renderBox2 =
          targetCup.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox1 != null && renderBox2 != null) {
        final distance = _calculateDistance(
          renderBox1.localToGlobal(Offset.zero),
          renderBox2.localToGlobal(Offset.zero),
        );
        if (distance < proximityThreshold) {
          cup.color = Colors.green;
          adjacentHits++;
        }
      }
    }

    // Middle cup stays on the table — restore its color so it is not removed at end-turn.
    targetCup.color = currentTeam.color;

    // The cup that was first hit already awarded +1 to the shooting player.
    // The bomb score is (adjacentHits) total cups removed, so we distribute
    // (adjacentHits - 1) here to cancel that pre-existing +1 and arrive at
    // a net total equal to the number of cups actually removed by the bomb.
    final players = currentTeam.currentPlayers;
    if (players.isNotEmpty && adjacentHits > 0) {
      final scorePerPlayer = (adjacentHits - 1) / players.length;
      for (final player in players) {
        player.incrementScoreBy(scorePerPlayer);
      }
    }
  }

  void checkBallsBack(BuildContext ctx) {
    if (currentTeam.ballsBack()) {
      // Remove cups hit this round immediately so they cannot be tapped or
      // trigger bomb detection during the Balls Back second round of throws.
      for (final cup in currentTeam.cups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }
      for (final player in currentTeam.currentPlayers) {
        player.resetHitThisRound();
      }
      addEvent('Balls Back', currentTeam, null);
      DialogHelpers.showBallsBackDialog(ctx);
      notifyListeners();
    }
  }

  void checkOnFire(Player player, BuildContext ctx) {
    if (player.isOnFire()) {
      addEvent('On Fire', currentTeam, player);
      DialogHelpers.showOnFireDialog(ctx);
    }
  }

  void checkBitchCup(int index, BuildContext ctx) {
    if (currentTeam.cups
            .every((cup) => cup.isVisible && cup.color == currentTeam.color) &&
        index == 4 &&
        currentTeam.cups.length == 10) {
      addEvent('Bitchcup', currentTeam, null);
      DialogHelpers.showBitchCupDialog(ctx);
    }
  }

  void endTurn() {
    if (islandShotActive) {
      currentIslandShooter = null;
      toggleIslandCups();
    }

    if (bounceShotActive) {
      bounceShotActive = false;
      currentBounceShooter = null;
    }

    for (final player in currentTeam.currentPlayers) {
      if (player.hitThisRound == 0) {
        player.incrementMisses();
        player.incrementThrows();
      }
      player.resetHitThisRound();
    }

    for (final cup in currentTeam.cups) {
      if (cup.color == Colors.green) cup.isVisible = false;
    }

    // Increment round count once both teams have completed a turn
    // (i.e. when control passes back to team 1).
    isTeamOneTurn = !isTeamOneTurn;
    if (isTeamOneTurn) roundCount++;
    currentTeam = isTeamOneTurn ? team1 : team2;
    currentTeam.currentPlayers = currentTeam.rotatePlayers();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateIslandBackgroundColor());
    notifyListeners();
  }

  void toggleRearranged(BuildContext ctx) {
    final visibleCount = currentTeam.cups.where((cup) => cup.isVisible).length;
    if (visibleCount > 6) {
      DialogHelpers.showRearrangeErrorDialog(ctx);
      return;
    }
    addEvent('Rearranged', currentTeam, null);
    saveCurrentState();
    if (!currentTeam.isRearranged) {
      List<Cup> remainingCups = currentTeam.cups
          .where((cup) => cup.isVisible && cup.color == currentTeam.color)
          .toList();
      remainingCups = CupLayout.assignSpecificIndices(remainingCups);
      currentTeam.cups = remainingCups;
      currentTeam.isRearranged = true;
    }
    notifyListeners();
  }

  // ----- Island Logic -----

  void toggleIslandCups() {
    if (islandShotActive) {
      islandShotActive = false;
      // Reset by color, not by recalculating proximity — cup layout may have
      // changed since the highlight was applied (cups removed, rearranged).
      for (final cup in currentTeam.cups) {
        if (cup.color == Colors.yellow) cup.color = currentTeam.color;
      }
    } else {
      islandShotActive = true;
      for (final cup in currentTeam.cups) {
        if (_isIslandCup(cup)) cup.color = Colors.yellow;
      }
    }
    notifyListeners();
  }

  /// Selects the island shooter, marks the shot used, and activates the island highlight.
  void selectIslandShooter(Player player) {
    currentIslandShooter = player;
    player.islandAttempts++;
    islandShotActive = false;
    toggleIslandCups(); // notifyListeners inside
    if (currentTeam.players.every((p) => p.islandAttempts > 0)) {
      currentTeam.canIslandShot = false;
      islandBackgroundColor = Colors.grey;
      notifyListeners();
    }
  }

  bool isIslandCup(Cup cup) => _isIslandCup(cup);

  bool _isIslandCup(Cup cup) {
    const double proximityThreshold = 100.0;
    int closeCupsCount = 0;
    for (final otherCup in currentTeam.cups) {
      if (cup.index == otherCup.index || !otherCup.isVisible || !cup.isVisible) {
        continue;
      }
      final renderBox1 =
          cup.key.currentContext?.findRenderObject() as RenderBox?;
      final renderBox2 =
          otherCup.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox1 != null && renderBox2 != null) {
        final distance = _calculateDistance(
          renderBox1.localToGlobal(Offset.zero),
          renderBox2.localToGlobal(Offset.zero),
        );
        if (distance < proximityThreshold) closeCupsCount++;
      }
    }
    return closeCupsCount == 0;
  }

  void _updateIslandBackgroundColor() {
    final hasIslandCup =
        currentTeam.cups.any((c) => c.isVisible && _isIslandCup(c));
    islandBackgroundColor = (hasIslandCup && currentTeam.canIslandShot)
        ? Colors.amber
        : Colors.grey;
    notifyListeners();
  }

  // ----- Misc Utility -----

  double _calculateDistance(Offset pos1, Offset pos2) =>
      sqrt(pow(pos1.dx - pos2.dx, 2) + pow(pos1.dy - pos2.dy, 2));

  int getRandomCupIndex(List<Cup> cups, int cupIndex, Color teamColor) {
    final possible = cups.where((c) {
      return c.index != cupIndex &&
          c.isVisible &&
          (c.color == teamColor || c.color == Colors.yellow);
    }).toList();
    if (possible.isEmpty) throw Exception('No matching cups found');
    return possible[Random().nextInt(possible.length)].index;
  }

  // ----- Game End Helpers -----

  bool areAllCupsGone() => currentTeam.cups
      .every((cup) => !cup.isVisible || cup.color == Colors.green);

  void removeLastCupHit(int cupIndex) {
    final cup = currentTeam.cups.firstWhere((c) => c.index == cupIndex);
    cup.color = currentTeam.color;
    cup.isVisible = true;
    for (final p in currentTeam.players) {
      p.lastCupHit = false;
    }
    notifyListeners();
  }

  void setGameEnded() {
    gameEnded = true;
    final blueTeamWin =
        team1.cups.every((cup) => !cup.isVisible || cup.color == Colors.green);
    winner = blueTeamWin ? 'Team 1' : 'Team 2';
    // Count cups the winning team still had remaining (measure of dominance).
    final winningTeam = blueTeamWin ? team1 : team2;
    cupsRemainingWinner = winningTeam.cups
        .where((c) => c.isVisible && c.color != Colors.green)
        .length;
    if (winner == 'Team 1') {
      team1.wins++;
      team2.losses++;
    } else {
      team2.wins++;
      team1.losses++;
    }
    notifyListeners();
  }

  // ----- Player Stats -----

  void incrementPlayerScore(Player player) {
    player.incrementScore();
    notifyListeners();
  }

  void decrementPlayerScore(Player player) {
    player.decrementScore();
    notifyListeners();
  }

  void addCupToPlayer(Player player, int cupIndex) {
    player.hitCup(cupIndex);
    notifyListeners();
  }

  void incrementPlayerThrows(Player player) {
    player.incrementThrows();
    notifyListeners();
  }

  void incrementPlayerHitThisRound(Player player) {
    player.incrementHitThisRound();
    notifyListeners();
  }

  void incrementPlayerAirballs(Player player, BuildContext ctx) {
    player.incrementAirballs();
    final totalAirballs =
        currentTeam.players.fold<int>(0, (sum, p) => sum + p.airballs);
    if (totalAirballs % 3 == 0) {
      DialogHelpers.showAirballDialog(ctx, totalAirballs);
    }
    notifyListeners();
  }

  void setPlayerHitLastCup(Player player) {
    player.hitLastCup();
    notifyListeners();
  }

  void handleAirballRule(Player player, BuildContext ctx) {
    addEvent('Airball', currentTeam, player);
    saveCurrentState();
    incrementPlayerAirballs(player, ctx);
  }

  // ----- Undo / Redo Stack -----

  void saveCurrentState() async {
    _actionStack.add({
      'team1': team1.clone(),
      'team2': team2.clone(),
      'isTeamOneTurn': isTeamOneTurn,
      'islandShotActive': islandShotActive,
      'currentIslandShooter': currentIslandShooter,
      'events': List<String>.from(_events),
    });
    _events.clear();
    await FirestoreService.instance
        .updateGameDoc(id, team1: team1, team2: team2);
    notifyListeners();
  }

  void addEvent(String eventType, Team team, Player? player) async {
    final event = await FirestoreService.instance
        .addEvent(id, eventType, team, player, roundNumber: roundCount);
    _events.add(event);
  }

  void removeEvent(String event) {
    unawaited(FirestoreService.instance.deleteEvent(id, event));
  }

  void undoLastAction() {
    if (_actionStack.isEmpty) return;
    final lastState = _actionStack.removeLast();
    team1 = lastState['team1'];
    team2 = lastState['team2'];
    isTeamOneTurn = lastState['isTeamOneTurn'];
    islandShotActive = lastState['islandShotActive'];
    currentIslandShooter = lastState['currentIslandShooter'];
    for (final event in (lastState['events'] as List<String>)) {
      removeEvent(event);
    }
    currentTeam = isTeamOneTurn ? team1 : team2;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateIslandBackgroundColor());
    notifyListeners();
  }

  // ----- Firestore Stats -----

  Future<User?> saveGameStatistics() async {
    if (winner == 'Team 1') {
      for (final player in team1.players) {
        player.isWinner = true;
      }
    } else {
      for (final player in team2.players) {
        player.isWinner = true;
      }
    }

    final updatedUsers = await FirestoreService.instance.saveGame(
      team1: team1.players,
      team2: team2.players,
    );

    for (final user in updatedUsers) {
      AchievementsScreen.checkAchievements(user);
    }

    await FirestoreService.instance.updateGameDoc(
      id,
      team1: team1,
      team2: team2,
      winner: winner,
      endedAt: true,
      roundCount: roundCount,
      cupsRemainingWinner: cupsRemainingWinner,
    );

    for (final invitationId in invitations) {
      await FirestoreService.instance.deleteGameInvitation(invitationId);
    }

    // Return the updated User for the current player so the caller can
    // call updateCurrentUser() *after* navigation (calling updateUser here
    // triggers notifyListeners → GoRouter rebuild → disposes the dialog).
    final userExists = updatedUsers.any((u) => u.id == _userProvider.user?.id);
    return userExists
        ? updatedUsers.firstWhere((u) => u.id == _userProvider.user?.id)
        : null;
  }

  Future<void> updateCurrentUser(User user) async {
    await _userProvider.updateUser(user);
  }
}
