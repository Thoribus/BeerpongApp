import 'dart:async';
import 'package:beerpongapp/models/event.dart';
import 'package:beerpongapp/screens/achievements_screen.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';

import '../../models/cup.dart';
import '../../models/player.dart';
import '../../models/team.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.id,
    required this.players1,
    required this.players2,
    required this.selectedRules,
    required this.startingTeam,
    required this.invitations,
  });

  final String id;
  final List<Player> players1;
  final List<Player> players2;
  final Map<String, bool> selectedRules;
  final bool startingTeam;
  final List<String> invitations;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  //region ----- Game/Team/Player State -----
  late String id;
  late Map<String, bool> selectedRules;
  late List<String> invitations;

  late Team team1;
  late Team team2;
  late Team currentTeam;

  bool gameEnded = false;
  late bool isTeamOneTurn;
  String winner = '';

  // Island shot logic
  bool islandShotActive = false;
  Player? currentIslandShooter;
  Color islandBackgroundColor = Colors.grey;
  //endregion

  //region ----- Page/Undo/Loading State -----
  final List<Map<String, dynamic>> _actionStack = [];
  final List<GameEvent> _events = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Future<void> _loadGameFuture;
  //endregion

  //region ----- Lifecycle -----
  @override
  void initState() {
    super.initState();
    _loadGameFuture = _loadGameState();
    _pageController.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    if (!gameEnded) {
      GamePersistence.saveGameState(
          id: id,
          team1: team1,
          team2: team2,
          isTeamOneTurn: isTeamOneTurn,
          islandShotActive: islandShotActive,
          invitations: invitations,
          selectedRules: selectedRules); // Save if the game hasn't ended
    }
    _pageController.dispose();
    super.dispose();
  }
  //endregion

  //region ----- Page Controller Logic -----
  void _handlePageChange() {
    final pageIndex = _pageController.page?.round() ?? 0;
    if (_currentPage != pageIndex) {
      setState(() => _currentPage = pageIndex);
    }
  }
  //endregion

  //region ----- Persistent Storage (Save/Load) -----
  Future<void> _loadGameState() async {
    Map<String, dynamic>? map = await GamePersistence.loadGameState();
    if (map == null) {
      // No saved data -> init teams from scratch
      setState(() {
        id = widget.id;
        team1 = Team(
          color: Colors.blue,
          players: widget.players1,
          cups: List.generate(
              10, (index) => Cup(index: index, color: Colors.blue)),
        );
        team2 = Team(
          color: Colors.red,
          players: widget.players2,
          cups: List.generate(
              10, (index) => Cup(index: index, color: Colors.red)),
        );
        isTeamOneTurn = widget.startingTeam;
        currentTeam = isTeamOneTurn ? team1 : team2;
        currentTeam.currentPlayers = currentTeam.rotatePlayers();
        invitations = widget.invitations;
        selectedRules = widget.selectedRules;
      });
      return;
    }

    setState(() {
      id = map['id'];
      team1 = Team.fromJson(map['team1']);
      team2 = Team.fromJson(map['team2']);
      isTeamOneTurn = map['isTeamOneTurn'] ?? false;
      islandShotActive = map['islandShotActive'] ?? false;
      invitations = List<String>.from(map['invitations']);
      selectedRules = Map<String, bool>.from(map['selectedRules']);

      // Current team
      currentTeam = isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();

      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateIslandBackgroundColor());
    });
  }
  //endregion

  /// Maps avatarKey -> local asset path (e.g. 'cat' -> 'assets/avatars/cat.png').
  String _mapAvatarKeyToAsset(String avatarKey) {
    if (avatarKey.isEmpty) return '';
    return 'assets/avatars/$avatarKey.svg';
  }

  //region ----- Core Game Logic Methods -----
  /// Called when a cup is hit. Checks if the cup is already green or not.
  void _handleCupHit(int index) {
    setState(() {
      final cup = currentTeam.cups.firstWhere((c) => c.index == index);
      if (cup.color == Colors.green) {
        // If cup is already green, check for proximity-based hits
        _checkProximity(index);
      } else {
        // Mark new hit -> cup turns green
        _checkBallsBack();
        _checkBitchCup(index);
        cup.color = Colors.green;
      }
    });
  }

  /// Checks other cups near the given cup. If within the threshold, mark them.
  void _checkProximity(int index) {
    const double proximityThreshold = 100.0;
    double adjacentHits = 0.0;

    // Find the target cup
    final targetCup = currentTeam.cups.firstWhere(
        (cup) => cup.index == index && cup.isVisible,
        orElse: () => Cup(index: -1, color: Colors.transparent));

    // If not found or not visible, do nothing
    if (targetCup.index == -1) return;

    // Check every other visible cup to see if it's close enough
    for (final cup in currentTeam.cups) {
      if (cup.index == index || !cup.isVisible) continue;

      final renderBox1 =
          cup.key.currentContext?.findRenderObject() as RenderBox?;
      final renderBox2 =
          targetCup.key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox1 != null && renderBox2 != null) {
        final position1 = renderBox1.localToGlobal(Offset.zero);
        final position2 = renderBox2.localToGlobal(Offset.zero);
        final distance = _calculateDistance(position1, position2);

        if (distance < proximityThreshold) {
          cup.color = Colors.green; // mark as hit
          adjacentHits++;
        }
      }
    }

    // Revert the originally hit cup's color
    targetCup.color = currentTeam.color;

    // Reward the player(s) who hit that cup
    for (final player in currentTeam.currentPlayers) {
      if (player.cupsHit.contains(index)) {
        // e.g. player.incrementScoreBy(...) based on adjacency
        player.incrementScoreBy(adjacentHits / 2 - 1);
      }
    }
  }

  /// Checks if a player is “On Fire” (3 consecutive hits) and shows a dialog.
  void _checkOnFire(Player player) {
    if (player.isOnFire()) {
      DialogHelpers.showOnFireDialog(this);
    }
  }

  /// If all teammates hit in one round, triggers “Balls Back.”
  void _checkBallsBack() {
    if (currentTeam.ballsBack()) {
      setState(() {
        for (final player in currentTeam.currentPlayers) {
          player.resetHitThisRound();
        }
      });
      DialogHelpers.showBallsBackDialog(this);
    }
  }

  /// If it’s the “bitch cup,” show the appropriate dialog.
  void _checkBitchCup(int index) {
    if (currentTeam.cups
            .every((cup) => cup.isVisible && cup.color == currentTeam.color) &&
        index == 4 &&
        currentTeam.cups.length == 10) {
      DialogHelpers.showBitchCupDialog(this);
    }
  }

  /// Confirm all cups are assigned. Switches turn to the other team.
  void endTurn() {
    setState(() {
      // If island shot is still active, deactivate and revert highlight
      if (islandShotActive) {
        currentIslandShooter = null;
        _toggleIslandCups();
      }

      // For each player who didn’t hit any cup -> mark a miss
      for (final player in currentTeam.currentPlayers) {
        if (player.hitThisRound == 0) {
          _incrementPlayerMisses(player);
          _incrementPlayerThrows(player);
        }
        player.resetHitThisRound();
      }

      // Hide the green cups for the next turn
      for (final cup in currentTeam.cups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }

      // Switch teams
      isTeamOneTurn = !isTeamOneTurn;
      currentTeam = isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIslandBackgroundColor();
      });
    });
  }

  /// Possibly rearrange cups if allowed (6 or fewer visible cups).
  void toggleRearranged() {
    final visibleCount = currentTeam.cups.where((cup) => cup.isVisible).length;
    if (visibleCount > 6) {
      DialogHelpers.showRearrangeErrorDialog(this);
      return;
    }
    saveCurrentState(GameEvent(
        eventType: "Rearranged", team: currentTeam.color.value.toString()));
    setState(() {
      if (!currentTeam.isRearranged) {
        // Filter only cups that match the current color & are visible
        List<Cup> remainingCups = currentTeam.cups
            .where((cup) => cup.isVisible && cup.color == currentTeam.color)
            .toList();

        remainingCups = CupLayout.assignSpecificIndices(remainingCups);
        currentTeam.cups = remainingCups;
        currentTeam.isRearranged = true;
      }
    });
  }
  //endregion

  //region ----- Island Logic -----
  /// Highlights (yellow) or reverts (team color) the island cups if found.
  void _toggleIslandCups() {
    setState(() {
      if (islandShotActive) {
        // Revert highlight
        islandShotActive = false;
        for (final cup in currentTeam.cups) {
          if (_isIslandCup(cup)) {
            cup.color = currentTeam.color;
          }
        }
      } else {
        // Highlight
        islandShotActive = true;
        for (final cup in currentTeam.cups) {
          if (_isIslandCup(cup)) {
            cup.color = Colors.yellow;
          }
        }
      }
    });
  }

  /// Shows a dialog to pick the player who will perform the island shot.
  Future<void> _highlightIslandCups() async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers.where((p) => !p.islandShotUsed).toList(),
      (player) {
        saveCurrentState(
            GameEvent(eventType: "Hightlight Island", player: player.name));
        setState(() {
          currentIslandShooter = player;
          player.islandShotUsed = true;
          islandShotActive = false;
          _toggleIslandCups();

          // If all have used the island shot, disable it
          if (currentTeam.players.every((p) => p.islandShotUsed)) {
            currentTeam.canIslandShot = false;
            islandBackgroundColor = Colors.grey;
          }
        });
      },
    );
  }

  /// Check if the given cup is isolated (no adjacent cups).
  bool _isIslandCup(Cup cup) {
    const double proximityThreshold = 100.0;
    int closeCupsCount = 0;

    for (final otherCup in currentTeam.cups) {
      if (cup.index == otherCup.index ||
          !otherCup.isVisible ||
          !cup.isVisible) {
        continue;
      }
      final renderBox1 =
          cup.key.currentContext?.findRenderObject() as RenderBox?;
      final renderBox2 =
          otherCup.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox1 != null && renderBox2 != null) {
        final position1 = renderBox1.localToGlobal(Offset.zero);
        final position2 = renderBox2.localToGlobal(Offset.zero);
        final distance = _calculateDistance(position1, position2);

        if (distance < proximityThreshold) {
          closeCupsCount++;
        }
      }
    }
    return closeCupsCount == 0;
  }

  /// Handles an island shot scenario.
  Future<void> handleIslandShot(int cupIndex) async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player and Shot Result',
      currentTeam.currentPlayers,
      (player) {
        saveCurrentState(
            GameEvent(eventType: "Island Shot", player: player.name));
        // If chosen player == currentIslandShooter => island “power shot”
        if (player == currentIslandShooter) {
          setState(() {
            _toggleIslandCups();
            currentIslandShooter = null;
          });
          _incrementPlayerScore(player);
          _addCupToPlayer(player, cupIndex);
          _incrementPlayerHitThisRound(player);
          _incrementPlayerThrows(player);
          _handleCupHit(cupIndex);

          // Attempt random extra cup
          try {
            final extraIndex = getRandomCupIndex(
                currentTeam.cups, cupIndex, currentTeam.color);
            _handleCupHit(extraIndex);
            _addCupToPlayer(player, extraIndex);
            _incrementPlayerScore(player);
          } catch (_) {
            debugPrint('No matching cups found for island shot bonus.');
          }
        } else {
          // Normal hit
          _incrementPlayerScore(player);
          _addCupToPlayer(player, cupIndex);
          _incrementPlayerHitThisRound(player);
          _incrementPlayerThrows(player);
          _handleCupHit(cupIndex);
          _checkOnFire(player);
        }
        _checkGameEnd(player, cupIndex);
      },
    );
  }
  //endregion

  //region ----- Misc Utility & Stats Methods -----
  double _calculateDistance(Offset pos1, Offset pos2) {
    return sqrt(pow(pos1.dx - pos2.dx, 2) + pow(pos1.dy - pos2.dy, 2));
  }

  double _calculateHitRate(num score, int throws) {
    if (throws == 0) return 0.0;
    return (score / throws) * 100.0;
  }

  int getRandomCupIndex(List<Cup> cups, int cupIndex, Color teamColor) {
    final possibleCups = cups.where((c) {
      return c.index != cupIndex &&
          c.isVisible &&
          (c.color == teamColor || c.color == Colors.yellow);
    }).toList();

    if (possibleCups.isEmpty) {
      throw Exception('No matching cups found');
    }

    return possibleCups[Random().nextInt(possibleCups.length)].index;
  }

  /// Updates the background color of the island shot button
  /// based on whether an island shot can still happen.
  void _updateIslandBackgroundColor() {
    final hasIslandCup =
        currentTeam.cups.any((c) => c.isVisible && _isIslandCup(c));
    islandBackgroundColor = (hasIslandCup && currentTeam.canIslandShot)
        ? Colors.amber
        : Colors.grey;
  }
  //endregion

//region ----- Checking for Game End / Nachwurf -----
  void _checkGameEnd(Player player, int cupIndex) async {
    final allCupsGone = currentTeam.cups.every(
      (cup) => !cup.isVisible || cup.color == Colors.green,
    );
    if (!allCupsGone) return; // Not all cups are gone => do nothing

    // If “Nachwurf” is active and we’re not on the special extra cup => let enemy defend
    if (selectedRules['Nachwurf'] == true && cupIndex != 11) {
      final enemyHit = await _handleNachwurf(cupIndex);
      if (enemyHit) {
        // The enemy canceled the last cup => revert and do NOT end the game
        _decrementPlayerScore(player);
        return;
      }
      // If we reach here => enemy failed to defend => game ends
    }

    // Now the game truly ends
    setState(() {
      gameEnded = true;
      final blueTeamWin = team1.cups
          .every((cup) => !cup.isVisible || cup.color == Colors.green);
      winner = blueTeamWin ? 'Team 1' : 'Team 2';
    });
    _setPlayerHitLastCup(player);

    await GamePersistence.clearGameState(false);
    await _saveGameStatistics();

    // Instead of showGameEndDialog, let’s push GameHighlightsScreen
    await DialogHelpers.showGameEndDialog(context, currentTeam.players);

    //await DialogHelpers.showGameEndDialog(this, currentTeam.players);
  }

  Future<bool> _handleNachwurf(int cupIndex) async {
    final enemyTeam = (currentTeam == team1) ? team2 : team1;

    // Wait for a Player? result
    final chosenPlayer = await DialogHelpers.showNachwurfSelectionDialog(
      context,
      'Enemy Team\'s Last Turn',
      enemyTeam.players,
    );

    // If chosenPlayer == null => user canceled => enemyHit = false
    // If chosenPlayer != null => enemyHit = true => revert the last cup
    if (chosenPlayer != null) {
      setState(() => chosenPlayer.defended++);
      saveCurrentState(
          GameEvent(eventType: "Defended", player: chosenPlayer.name));
      _removeLastCupHit(cupIndex);
      return true; // enemyHit
    } else {
      return false; // user canceled => no hit
    }
  }

  void _removeLastCupHit(int cupIndex) {
    final undoneCup =
        currentTeam.cups.firstWhere((cup) => cup.index == cupIndex);
    undoneCup.color = currentTeam.color;
    undoneCup.isVisible = true;
    for (final p in currentTeam.players) {
      p.lastCupHit = false;
    }
  }
  //endregion

  //region ----- Player Stats Updates -----
  void _incrementPlayerScore(Player player) =>
      setState(() => player.incrementScore());
  void _decrementPlayerScore(Player player) =>
      setState(() => player.decrementScore());
  void _addCupToPlayer(Player player, int cupIndex) =>
      setState(() => player.hitCup(cupIndex));
  void _incrementPlayerThrows(Player player) =>
      setState(() => player.incrementThrows());
  void _incrementPlayerMisses(Player player) =>
      setState(() => player.incrementMisses());
  void _incrementPlayerHitThisRound(Player player) =>
      setState(() => player.incrementHitThisRound());

  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      final totalAirballs =
          currentTeam.players.fold<int>(0, (sum, p) => sum + p.airballs);
      if (totalAirballs % 3 == 0) {
        DialogHelpers.showAirballDialog(this, totalAirballs);
      }
    });
  }

  void _setPlayerHitLastCup(Player player) =>
      setState(() => player.hitLastCup());

  /// Handle what happens when a player throws an airball.
  void _handleAirballRule(Player player) {
    saveCurrentState(GameEvent(eventType: "Airball", player: player.name));
    _incrementPlayerAirballs(player);
  }

  /// Handle what happens when a player hits a cup.
  void _handleNormalHit(Player player, int cupIndex) {
    saveCurrentState(GameEvent(eventType: "Normal Hit", player: player.name));
    _addCupToPlayer(player, cupIndex);
    _incrementPlayerThrows(player);
    _incrementPlayerHitThisRound(player);
    _incrementPlayerScore(player);
    _handleCupHit(cupIndex);
    _checkOnFire(player);
    _checkGameEnd(player, cupIndex);
  }

  /// Handle what happens when a player hits the Death Cup.
  void _handleDeathCup(Player player) {
    saveCurrentState(GameEvent(eventType: "Death Cup", player: player.name));
    for (final cup in currentTeam.cups) {
      if (cup.color == currentTeam.color) {
        _addCupToPlayer(player, cup.index);
        _handleCupHit(cup.index);
        _incrementPlayerScore(player);
        _incrementPlayerThrows(player);
      }
    }
    _checkGameEnd(player, 11);
  }
  //endregion

  //region ----- Undo/Redo Stack -----
  void saveCurrentState(GameEvent event) async {
    _actionStack.add({
      'team1': team1.clone(),
      'team2': team2.clone(),
      'isTeamOneTurn': isTeamOneTurn,
      'islandShotActive': islandShotActive,
      'currentIslandShooter': currentIslandShooter,
    });
    _events.add(event);
    List<Map<String, dynamic>> eventsJson = [];
    for (final event in _events) {
      eventsJson.add(event.toJson());
    }

    await FirestoreService()
        .updateGameDoc(id, team1: team1, team2: team2, events: eventsJson);
  }

  void _undoLastAction() async {
    if (_actionStack.isEmpty) return;

    final lastState = _actionStack.removeLast();
    setState(() {
      team1 = lastState['team1'];
      team2 = lastState['team2'];
      isTeamOneTurn = lastState['isTeamOneTurn'];
      islandShotActive = lastState['islandShotActive'];
      currentIslandShooter = lastState['currentIslandShooter'];
      _events.removeLast();

      currentTeam = isTeamOneTurn ? team1 : team2;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateIslandBackgroundColor());
    });

    List<Map<String, dynamic>> eventsJson = [];
    for (final event in _events) {
      eventsJson.add(event.toJson());
    }

    FirestoreService()
        .updateGameDoc(id, team1: team1, team2: team2, events: eventsJson);
  }
  //endregion

  //region ----- Show Various Dialogs (AwesomeDialog) -----

  /// Dialog for picking a player for a normal cup selection.
  Future<void> showPlayerSelectionDialog(
      BuildContext context, int cupIndex) async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers,
      (player) {
        _handleNormalHit(player, cupIndex);
      },
    );
  }
  //endregion

  //region ----- Saving Stats to Firestore -----
  Future<void> _saveGameStatistics() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (winner == "Team 1") {
      for (final player in team1.players) {
        setState(() {
          player.isWinner = true;
        });
      }
    } else {
      for (final player in team2.players) {
        setState(() {
          player.isWinner = true;
        });
      }
    }
    final updatedUsers = await FirestoreService().saveGame(
      team1: team1.players,
      team2: team2.players,
    );

    // Give new titles to players if they unlocked any
    for (final user in updatedUsers) {
      AchievementsScreen.checkAchievements(user);
    }

    FirestoreService()
        .updateGameDoc(id, team1: team1, team2: team2, winner: winner);

    // Delete all game invitations
    for (String invitationId in invitations) {
      FirestoreService().deleteGameInvitation(invitationId);
    }

    // Update current user in UserProvider if found in updatedUsers
    final userExists = updatedUsers.any((u) => u.id == userProvider.user?.id);
    if (userExists) {
      final currentUser =
          updatedUsers.firstWhere((u) => u.id == userProvider.user?.id);
      userProvider.updateUser(currentUser);
    }
  }
  //endregion

  //region ----- UI Build Methods -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _loadGameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                _buildTopNavButtons(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCurrentGamePage(),
                      _buildGameStatsPage(currentTeam.color),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  /// The top AppBar with title.
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Current Game',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Color(0xFFF0AE1D),
      actions: [
        IconButton(
          icon: const Icon(Icons.scatter_plot_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  /// The “View Table” / “View Game Stats” buttons at the top of the screen.
  Widget _buildTopNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed:
              _currentPage == 0 ? null : () => _pageController.jumpToPage(0),
          child: Text(
            'View Table',
            style: TextStyle(
                color: _currentPage == 0 ? Colors.amber : Colors.white),
          ),
        ),
        const VerticalDivider(color: Colors.white, width: 20, thickness: 2),
        TextButton(
          onPressed:
              _currentPage == 1 ? null : () => _pageController.jumpToPage(1),
          child: Text(
            'View Game Stats',
            style: TextStyle(
                color: _currentPage == 1 ? Colors.amber : Colors.white),
          ),
        ),
      ],
    );
  }

  void onCupTap(int cupIndex) {
    if (islandShotActive) {
      handleIslandShot(cupIndex);
    } else {
      showPlayerSelectionDialog(context, cupIndex);
    }
  }

  /// The main “Game Table” page: cups layout, players, special rules.
  Widget _buildCurrentGamePage() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // The background table area
          Positioned(
            top: 100.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [Colors.brown.shade700, Colors.brown.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 4.0),
              ),
              child: Column(
                children: [
                  // The cups
                  Expanded(
                    flex: 3,
                    child: CupLayout.buildCupsArea(state: this),
                  ),
                  const SizedBox(height: 20),
                  // Player names
                  Expanded(
                    flex: 1,
                    child: GridView.builder(
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling within the grid
                      padding: const EdgeInsets.all(
                          8.0), // Add padding around the grid
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        mainAxisSpacing: 8.0, // Vertical spacing
                        crossAxisSpacing: 8.0, // Horizontal spacing
                        childAspectRatio:
                            2.5, // Ensures cards have identical dimensions
                      ),
                      itemCount: currentTeam.currentPlayers.length
                          .clamp(0, 4), // Max 4 players
                      itemBuilder: (context, index) {
                        return _buildPlayerName(
                            currentTeam.currentPlayers[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          // Floating Action Buttons for special rules at the top
          Positioned(
            top: 20.0,
            left: 16.0,
            right: 16.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Deathcup (if applicable) or placeholder
                if (selectedRules["Deathcup"] == true)
                  FloatingActionButton(
                    onPressed: () => DialogHelpers.showDeathcupSelectionDialog(
                        this, currentTeam, (player) => _handleDeathCup(player)),
                    backgroundColor: Colors.amber,
                    heroTag: "Deathcup",
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100),
                        topLeft: Radius.circular(100),
                      ),
                    ),
                    child: const Icon(BeerpongIcons.skull, size: 35),
                  )
                else
                  const SizedBox(width: 56.0), // placeholder

                // Airball button in the middle
                FloatingActionButton.extended(
                  backgroundColor: Colors.amber,
                  heroTag: "airball",
                  onPressed: () =>
                      DialogHelpers.showAirballPlayerSelectionDialog(this,
                          currentTeam, (player) => _handleAirballRule(player)),
                  tooltip: 'Airball',
                  label: const Text('Airball'),
                  icon: const Icon(BeerpongIcons.airball, size: 45),
                ),

                // Island (if applicable) or placeholder
                if (selectedRules["Island"] == true)
                  FloatingActionButton(
                    backgroundColor: islandBackgroundColor,
                    heroTag: "Island",
                    onPressed: currentTeam.canIslandShot &&
                            currentTeam.cups
                                .any((c) => c.isVisible && _isIslandCup(c))
                        ? _highlightIslandCups
                        : null, // disable if not available
                    child: const Icon(BeerpongIcons.palm_tree, size: 45),
                  )
                else
                  const SizedBox(width: 56.0), // placeholder
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Builds a player name widget with consistent styling.
  Widget _buildPlayerName(Player player) {
    return Container(
      padding: const EdgeInsets.all(8.0), // Inner padding
      decoration: BoxDecoration(
        color: Colors.brown.shade600, // Background color for card
        border: Border.all(
          color: Colors.grey.withOpacity(0.5), // Semi-transparent border
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
      ),
      child: Row(
        children: [
          player.user == null
              ? const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                )
              : CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: SvgPicture.asset(
                      _mapAvatarKeyToAsset(player.user!.avatarKey),
                      fit: BoxFit.cover,
                      width: 20 * 2,
                      height: 20 * 2,
                    ),
                  ),
                ),
          const SizedBox(width: 8.0), // Space between avatar and text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.length > 13
                      ? '${player.name.substring(0, 12)}...' // Truncate long names
                      : player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                  overflow: TextOverflow.ellipsis, // Handles very long names
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Level: 1', // Dummy level
                  style: TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The "Game Stats" page showing possible game actions and team brackets.
  Widget _buildGameStatsPage(Color teamColor) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Actions',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildGameActions(currentTeam.players),
              const SizedBox(height: 10),
              const Text(
                'Team Statistics',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTeamBrackets(),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays possible game actions for this turn.
  Widget _buildGameActions(List<Player> players) {
    // Define actions with their properties
    List<Map<String, dynamic>> actions = [
      {
        'actionTitle': 'Bitchcup',
        'progressText': 'loosen your belt',
        'teamColor': currentTeam.color,
        'playerName': players[0].name,
        'teamName': 'Team Blue',
        'playerIcon': Icons.dry_cleaning_outlined,
        'progressValue': 0.7, // create when 2 of 3 airballs are hit
        'isActive': false,
      },
      {
        'actionTitle': 'On fire',
        'progressText': 'get your balls back',
        'teamColor': currentTeam.color,
        'playerName': players[0].name,
        'teamName': '2 in a row',
        'playerIcon': Icons.local_fire_department,
        'progressValue': 0.7, // create when 2 of 3 airballs are hit
        'isActive': true,
      },
      {
        'actionTitle': '3rd Airball',
        'progressText': '1 airball until shot',
        'teamColor': currentTeam.color,
        'playerName': players[0].name,
        'teamName': 'Team Red',
        'playerIcon': BeerpongIcons.airball,
        'progressValue': 0.5,
        'isActive': false,
      },
      {
        'actionTitle': 'Island',
        'progressText': 'One hit for two cups',
        'teamColor': currentTeam.color,
        'playerName': players[0].name,
        'teamName': '2 ready',
        'playerIcon': BeerpongIcons.palm_tree,
        'progressValue': 0.8,
        'isActive': currentTeam.canIslandShot,
      },
    ];

    return Column(
      children: actions
          .where((action) => action['isActive'] == true)
          .map((action) => _buildActionBracket(action))
          .toList(),
    );
  }

  /// Builds an individual action bracket.
  Widget _buildActionBracket(Map<String, dynamic> actionData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amberAccent, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionData['actionTitle'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: actionData['progressText'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: actionData['teamColor'],
                        ),
                      ),
                      const TextSpan(
                        text: ' - ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      TextSpan(
                        text: '${actionData['playerName']} is making a move',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: actionData['teamColor'].withOpacity(0.2),
                child: Icon(actionData['playerIcon'],
                    color: actionData['teamColor']),
              ),
              const SizedBox(height: 4),
              Text(
                actionData['teamName'],
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays team brackets at the bottom.
  Widget _buildTeamBrackets() {
    return Column(
      children: [
        _buildTeamBracket('Team Blue', Colors.blue, team1.players),
        const SizedBox(height: 20),
        _buildTeamBracket('Team Red', Colors.red, team2.players),
      ],
    );
  }

  /// Builds a single team bracket section with a gradient background.
  Widget _buildTeamBracket(String teamName, Color color, List<Player> players) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.symmetric(
                  outside: BorderSide.none, inside: BorderSide.none),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration:
                      BoxDecoration(color: Colors.white.withOpacity(0.2)),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Player',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('S',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('A',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('T',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('M',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
                ...players.map((player) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(player.name,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.score}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.airballs}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.throws}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.misses}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom navigation with Undo, Rearrange, End Turn.
  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo
          FloatingActionButton(
            backgroundColor: Colors.amber,
            heroTag: "undo",
            onPressed: _undoLastAction,
            tooltip: 'Go Back one turn.',
            child: const Icon(Icons.undo),
          ),
          // Rearrange
          FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            heroTag: "rearrange",
            onPressed: toggleRearranged,
            tooltip: 'Rearrange the current cups.',
            label: const Text('Rearrange'),
            icon: const Icon(BeerpongIcons.umstellen, size: 35),
          ),
          // End Turn
          FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            heroTag: "end",
            onPressed: () => DialogHelpers.confirmEndTurn(this),
            tooltip: 'All cups selected. Next turn.',
            label: const Text('End Turn'),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
  //endregion
}
