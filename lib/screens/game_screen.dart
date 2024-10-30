import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/screens/base_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:provider/provider.dart';
import '../models/cup.dart';
import '../models/player.dart';
import 'dart:math';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/team.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.title,
    required this.players1,
    required this.players2,
    required this.selectedRules,
    required this.startingTeam,
  });

  final String title;
  final List<Player> players1;
  final List<Player> players2;
  final Map<String, bool> selectedRules;
  final bool startingTeam;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Map<String, bool> selectedRules = widget.selectedRules;

  late Team team1;
  late Team team2;
  late Team currentTeam;

  bool gameEnded = false;

  late bool isTeamOneTurn = widget.startingTeam;
  bool islandShotActive = false;
  Player? currentIslandShooter = null;

  final List<Map<String, dynamic>> _actionStack = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late Future<void> _loadGameFuture;
  
  Color islandBackgroundColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadGameFuture = _loadGameState();
    _pageController.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    super.dispose();
    if (!gameEnded) _saveGameState();
    _pageController.dispose();
  }

  void _handlePageChange() {
    int page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _showSelectionDialog(BuildContext context, String title,
      List<Player> players, Function(Player) onSelected) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: players.map((player) {
                return ElevatedButton(
                  child: Text(player.name),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onSelected(player);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPlayerSelectionDialog(
      BuildContext context, int cupIndex) async {
    await _showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers,
      (player) {
        _saveCurrentState();
        _addCupToPlayer(player, cupIndex);
        _incrementPlayerThrows(player);
        _incrementPlayerHitThisRound(player);
        _incrementPlayerScore(player);
        _handleCupHit(cupIndex);
        _checkOnFire(player);
        _checkGameEnd(player, cupIndex);
      },
    );
  }

  Future<void> _showDeathcupSelectionDialog(BuildContext context) async {
    await _showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers,
      (player) {
        _saveCurrentState();
        for (var cup in currentTeam.cups) {
          if (cup.color == currentTeam.color) {
            _addCupToPlayer(player, cup.index);
            _handleCupHit(cup.index);
            _incrementPlayerScore(player);
            _incrementPlayerThrows(player);
          }
        }
        _checkGameEnd(player, 11);
      },
    );
  }

  void _checkOnFire(Player player) {
    if (player.isOnFire()) {
      _showOnFireDialog();
    }
  }

  Future<void> _showOnFireDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('On Fire!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Three consecutive hits!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _checkBallsBack() {
    if (currentTeam.ballsBack()) {
      setState(() {
        for (var player in currentTeam.currentPlayers) {
          player.resetHitThisRound();
        }
      });
      _showBallsBackDialog();
    }
  }

  Future<void> _showBallsBackDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Balls Back!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('All players hit this round!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _incrementPlayerScore(Player player) {
    setState(() {
      player.incrementScore();
    });
  }

  void _decrementPlayerScore(Player player) {
    setState(() {
      player.decrementScore();
    });
  }

  void _addCupToPlayer(Player player, int cupIndex) {
    setState(() {
      player.hitCup(cupIndex);
    });
  }

  void _incrementPlayerThrows(Player player) {
    setState(() {
      player.incrementThrows();
    });
  }

  void _incrementPlayerMisses(Player player) {
    setState(() {
      player.incrementMisses();
    });
  }

  void _incrementPlayerHitThisRound(Player player) {
    setState(() {
      player.incrementHitThisRound();
    });
  }

  void _handleCupHit(int index) {
    setState(() {
      if (currentTeam.cups.firstWhere((cup) => cup.index == index).color ==
          Colors.green) {
        _checkProximity(index);
      } else {
        print("hello");
        _checkBallsBack();
        _checkBitchCup(index);
        currentTeam.cups.firstWhere((cup) => cup.index == index).color =
            Colors.green;
      }
    });
  }

  void _checkBitchCup(int index) {
    if (currentTeam.cups
            .every((cup) => cup.isVisible && cup.color == currentTeam.color) &&
        index == 4 &&
        currentTeam.cups.length == 10) {
      _showBitchCupDialog();
    }
  }

  Future<void> _showBitchCupDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bitchcup!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bitchcup getroffen!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hosen runter!'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _setPlayerHitLastCup(Player player) {
    setState(() {
      player.hitLastCup();
    });
  }

  void toggleRearranged() {
    if (currentTeam.cups.where((cup) => cup.isVisible).length > 6) {
      _showRearrangeErrorDialog(context);
      return;
    }

    _saveCurrentState();

    setState(() {
      if (!currentTeam.isRearranged) {
        currentTeam.remainingCups = currentTeam.cups
            .where((cup) => cup.isVisible && cup.color == currentTeam.color)
            .toList();
        currentTeam.remainingCups =
            _assignSpecificIndices(currentTeam.remainingCups);
        currentTeam.cups = currentTeam.remainingCups;
        currentTeam.isRearranged = true;
      }
    });
  }

  void _toggleIslandCups() {
    setState(() {
      if (islandShotActive){
        islandShotActive = false;
        for (var cup in currentTeam.cups) {
          if (_isIslandCup(cup)) {
            cup.color = currentTeam.color;
          }
        }
      }
      else{
        islandShotActive = true;
        for (var cup in currentTeam.cups) {
          if (_isIslandCup(cup)) {
            cup.color = Colors.yellow;
          }
        }
      }
    });
  }

  Future<void> _highlightIslandCups() async{
    await _showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers
          .where((player) => player.islandShotUsed == false)
          .toList(),
      (player) {
        _saveCurrentState();
        setState(() {
          currentIslandShooter = player;  //to remember the player who is shooting the island shot
          player.islandShotUsed = true;   //to remember that the player has used the island shot
          islandShotActive = false;
          _toggleIslandCups();
          if (currentTeam.players.every((player) => player.islandShotUsed == true)) {
            currentTeam.canIslandShot = false;    //if all players have used the island shot, disable the island shot
            if (currentTeam.canIslandShot == false) {   //if the island shot is disabled, change the color of the button
              islandBackgroundColor = Colors.grey;
            }
          }
        });
      },
    );
  }

  bool _isIslandCup(Cup cup) {
    const double proximityThreshold = 100.0;
    int closeCupsCount = 0;

    for (var otherCup in currentTeam.cups) {
      if (cup.index != otherCup.index && otherCup.isVisible && cup.isVisible) {
        final renderBox1 =
            cup.key.currentContext?.findRenderObject() as RenderBox?;
        final renderBox2 =
            otherCup.key.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox1 != null && renderBox2 != null) {
          Offset position1 = renderBox1.localToGlobal(Offset.zero);
          Offset position2 = renderBox2.localToGlobal(Offset.zero);

          double distance = _calculateDistance(position1, position2);
          if (distance < proximityThreshold) {
            closeCupsCount++;
          }
        }
      }
    }
    return closeCupsCount == 0;
  }

  int getRandomCupIndex(List<Cup> cups, int cupIndex, Color teamColor) {
    // Filter the cups
    List<Cup> filteredCups = cups.where((cup) =>
        cup.index != cupIndex &&
        cup.isVisible &&
        (cup.color == teamColor || cup.color == Colors.yellow)).toList();

    // Check if there are any cups left after filtering
    if (filteredCups.isEmpty) {
      throw Exception('No matching cups found');
    }

    // Select a random cup from the filtered list
    Random random = Random();
    int randomIndex = random.nextInt(filteredCups.length);
    return filteredCups[randomIndex].index;
  }


  Future<void> _handleIslandShot(int cupIndex) async {
    await _showSelectionDialog(
      context,
      'Select Player and Shot Result',
      currentTeam.currentPlayers.toList(),
      (player) {
        _saveCurrentState();
        if (player == currentIslandShooter) {   //island hit
          setState(() {
            _toggleIslandCups();            
            currentIslandShooter = null;
          });
          _incrementPlayerScore(player);
          _addCupToPlayer(player, cupIndex);
          _incrementPlayerHitThisRound(player);
          _incrementPlayerThrows(player);
          _handleCupHit(cupIndex);
          (player);
          try {
            int islandIndex = getRandomCupIndex(currentTeam.cups, cupIndex, currentTeam.color); // Random cup hit
            _handleCupHit(islandIndex);
            _addCupToPlayer(player, islandIndex);
            _incrementPlayerScore(player); // Increment player score if no exception is thrown
          } catch (e) {
            // Handle the exception
            print('No matching cups found');
          }
        }

        else {  //normal hit
          _incrementPlayerScore(player);
          _addCupToPlayer(player, cupIndex);
          _incrementPlayerHitThisRound(player);
          _incrementPlayerThrows(player);
          _handleCupHit(cupIndex);
          _checkOnFire(player);
        }
        _checkGameEnd(player, cupIndex);
        }
    );
  }

  void _endTurn() {
    setState(() {
      if (islandShotActive) {
        currentIslandShooter = null;
        _toggleIslandCups(); // Reset island shot highlight
      }

      for (var player in currentTeam.currentPlayers) {
        if (player.hitThisRound == 0) {
          _incrementPlayerMisses(player);
          _incrementPlayerThrows(player);
        }
        print(player.toJson());
        player.resetHitThisRound();
      }

      for (var cup in currentTeam.cups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }

      isTeamOneTurn = !isTeamOneTurn;
      currentTeam = isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();
  
      WidgetsBinding.instance.addPostFrameCallback((_) {	
        setState(() {	
          islandBackgroundColor = (currentTeam.cups.any(
                          (element) => element.isVisible && _isIslandCup(element)) &&
                          currentTeam.canIslandShot)
                      ? Colors.amber
                      : Colors.grey;
        });
      });
    });
  }

  Future<void> _confirmEndTurn(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm End Turn'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to end your turn?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('End Turn'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _saveCurrentState();
                _endTurn();
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateDistance(Offset position1, Offset position2) {
    return sqrt(pow(position1.dx - position2.dx, 2) +
        pow(position2.dy - position1.dy, 2));
  }

  double _calculateHitRate(double score, int throws) {
    if (throws == 0) return 0.0;
    return (score / throws) * 100;
  }

  void _checkProximity(int index) {
    const double proximityThreshold = 100.0;
    double hitCups = 0.0;

    // Find the cup with the given index
    Cup? targetCup;
    for (Cup cup in currentTeam.cups) {
      if (cup.index == index && cup.isVisible) {
        targetCup = cup;
        break;
      }
    }

    if (targetCup == null) return;

    // Check proximity for all visible cups
    for (Cup cup in currentTeam.cups) {
      if (cup.index != index && cup.isVisible) {
        final renderBox1 =
            cup.key.currentContext?.findRenderObject() as RenderBox?;
        final renderBox2 =
            targetCup.key.currentContext?.findRenderObject() as RenderBox?;

        if (renderBox1 != null && renderBox2 != null) {
          Offset position1 = renderBox1.localToGlobal(Offset.zero);
          Offset position2 = renderBox2.localToGlobal(Offset.zero);

          double distance = _calculateDistance(position1, position2);
          if (distance < proximityThreshold) {
            hitCups++;
            cup.color = Colors.green;
          }
        }
      }
    }

    targetCup.color = currentTeam.color;
    for (var player in currentTeam.currentPlayers) {
      if (player.cupsHit.contains(index)) {
        player.incrementScoreBy(hitCups / 2 - 1);
      }
    }
  }

  Future<void> _showAirballPlayerSelectionDialog(BuildContext context) async {
    await _showSelectionDialog(
      context,
      'Select Player',
      currentTeam.currentPlayers,
      (player) {
        _saveCurrentState();
        _incrementPlayerAirballs(player);
      },
    );
  }

  Future<void> _showAirballDialog(BuildContext context, int airballs) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Airball Milestone'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Total airballs: $airballs'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Shots...'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      int teamAirballs =
          currentTeam.players.fold(0, (sum, player) => sum + player.airballs);
      if (teamAirballs % 3 == 0) {
        _showAirballDialog(context, teamAirballs);
      }
    });
  }

  Future<void> _saveGameState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('team1Cups', Cup.encodeList(team1.cups));
    prefs.setString('team1Players', Player.encodeList(team1.players));
    prefs.setBool('team1IsRearranged', team1.isRearranged);

    prefs.setString('team2Cups', Cup.encodeList(team2.cups));
    prefs.setString('team2Players', Player.encodeList(team2.players));
    prefs.setBool('team2IsRearranged', team2.isRearranged);

    prefs.setBool('isTeamOneTurn', isTeamOneTurn);
    prefs.setBool('islandShotActive', islandShotActive);
  }

  Future<void> _loadGameState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? team1Cups = prefs.getString('team1Cups');
    String? team1Players = prefs.getString('team1Players');
    bool team1IsRearranged = prefs.getBool('team1IsRearranged') ?? false;

    String? team2Cups = prefs.getString('team2Cups');
    String? team2Players = prefs.getString('team2Players');
    bool team2IsRearranged = prefs.getBool('team2IsRearranged') ?? false;

    bool? isTeamOneTurn = prefs.getBool('isTeamOneTurn');
    bool islandShotActive = prefs.getBool('islandShotActive') ?? false;

    setState(() {
      if (team1Cups != null && team1Players != null) {
        team1 = Team(
          color: Colors.blue,
          players: Player.decodeList(team1Players),
          cups: Cup.decodeList(team1Cups),
        );
        team1.isRearranged = team1IsRearranged;
      } else {
        team1 = Team(
          color: Colors.blue,
          players: widget.players1,
          cups: List.generate(
              10, (index) => Cup(index: index, color: Colors.blue)),
        );
      }

      if (team2Cups != null && team2Players != null) {
        team2 = Team(
          color: Colors.red,
          players: Player.decodeList(team2Players),
          cups: Cup.decodeList(team2Cups),
        );
        team2.isRearranged = team2IsRearranged;
      } else {
        team2 = Team(
          color: Colors.red,
          players: widget.players2,
          cups: List.generate(
              10, (index) => Cup(index: index, color: Colors.red)),
        );
      }

      if (isTeamOneTurn != null) this.isTeamOneTurn = isTeamOneTurn;
      this.islandShotActive = islandShotActive;
      currentTeam = this.isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();
      WidgetsBinding.instance.addPostFrameCallback((_) {	
        setState(() {	
          islandBackgroundColor = (currentTeam.cups.any(
                          (element) => element.isVisible && _isIslandCup(element)) &&
                          currentTeam.canIslandShot)
                      ? Colors.amber
                      : Colors.grey;
        });
      });
    });
  }

  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('team1Cups');
    await prefs.remove('team2Cups');
    await prefs.remove('team1Players');
    await prefs.remove('team2Players');
    await prefs.remove('isTeamOneTurn');
    await prefs.remove('isRearranged1');
    await prefs.remove('isRearranged2');
  }

  void _saveCurrentState() {
    _actionStack.add({
      'team1': team1.clone(),
      'team2': team2.clone(),
      'isTeamOneTurn': isTeamOneTurn,
      'islandShotActive': islandShotActive,
      'currentIslandShooter': currentIslandShooter,
    });
  }

  void _undoLastAction() {
    if (_actionStack.isEmpty) return;

    final lastState = _actionStack.removeLast();
    Team test = lastState["team1"];
    print(test.toString());
    setState(() {
      team1 = lastState['team1'];
      team2 = lastState['team2'];
      isTeamOneTurn = lastState['isTeamOneTurn'];
      islandShotActive = lastState['islandShotActive']; //island logic
      if (lastState['currentIslandShooter'] != null) {
        currentIslandShooter = lastState['currentIslandShooter']; //not always initialized
      }
      currentTeam = isTeamOneTurn ? team1 : team2;
      WidgetsBinding.instance.addPostFrameCallback((_) {	
        setState(() {	
          islandBackgroundColor = (currentTeam.cups.any(
                          (element) => element.isVisible && _isIslandCup(element)) &&
                          currentTeam.canIslandShot)
                      ? Colors.amber
                      : Colors.grey;
        });
      });
    });
  }

  void _checkGameEnd(Player player, int cupIndex) async {
    bool teamAllHit = currentTeam.cups
        .every((cup) => !cup.isVisible || cup.color == Colors.green);

    if (teamAllHit) {
      if (selectedRules['Nachwurf'] == true && cupIndex != 11) {
        bool enemyTurn = await _handleNachwurf(cupIndex);
        if (enemyTurn) {
          _decrementPlayerScore(player);
          return; // If the enemy hits a cup, cancel the last cup hit and don't end the game
        }
      }
      setState(() {
        gameEnded = true;
      });

      _setPlayerHitLastCup(player);
      await _clearGameState();
      await _saveGameStatistics();

      for (var player in team1.players) {
        print(player.toJson());
      }
      for (var player in team2.players) {
        print(player.toJson());
      }

      _showGameEndDialog(context, currentTeam.players);
    }
  }

  Future<bool> _handleNachwurf(int cupIndex) async {
    Team enemyTeam = currentTeam == team1 ? team2 : team1;
    bool enemyHit = false;

    await _showSelectionDialog(
      context,
      'Enemy Team\'s Last Turn',
      enemyTeam.players,
      (player) {
        setState(() {
          player.defended++;
        });
        _saveCurrentState();
        enemyHit = true;
        _removeLastCupHit(cupIndex);
      },
    );

    return enemyHit;
  }

  void _removeLastCupHit(int cupIndex) {
    setState(() {
      for (var player in currentTeam.players) {
        player.lastCupHit = false;
      }
      currentTeam.cups.firstWhere((cup) => cup.index == cupIndex).color =
          currentTeam.color;
      currentTeam.cups.firstWhere((cup) => cup.index == cupIndex).isVisible =
          true;
    });
  }

  Future<void> _showGameEndDialog(
      BuildContext context, List<Player> players) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ...players.map((player) => Text("${player.name} ")),
                const Text("have won the game!"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Go to Stats'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BaseScreen(selectedIndex: 3),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Go to Home'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BaseScreen(selectedIndex: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGameStatistics() async {
    bool blueTeamWin =
        team1.cups.every((cup) => !cup.isVisible || cup.color == Colors.green)
            ? false
            : true;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<User> updatedUsers = await FirestoreService().saveGame(
      team1: team1.players,
      team2: team2.players,
      winner: blueTeamWin ? "Team 1" : "Team 2",
    );

    // Check if the current user is in the updated users list
    bool userExists =
        updatedUsers.any((user) => user.id == userProvider.user?.id);
    // Find the updated current user and refresh the UserProvider
    if (userExists) {
      User currentUser =
          updatedUsers.firstWhere((user) => user.id == userProvider.user?.id);

      userProvider.updateUser(currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Game',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.withOpacity(0.75),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.scatter_plot_outlined),
            onPressed: () {},
          ),
        ],
      ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _currentPage == 0
                          ? null
                          : () {
                              _pageController.jumpToPage(0);
                            },
                      child: Text(
                        'View Table',
                        style: TextStyle(
                          color:
                              _currentPage == 0 ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      color: Colors.white,
                      width: 20,
                      thickness: 2,
                      indent: 5,
                      endIndent: 5,
                    ),
                    TextButton(
                      onPressed: _currentPage == 1
                          ? null
                          : () {
                              _pageController.jumpToPage(1);
                            },
                      child: Text(
                        'View Game Stats',
                        style: TextStyle(
                          color:
                              _currentPage == 1 ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
      backgroundColor: Colors.black,
    );
  }

  Column _buildCups(List<Cup> cups, bool isRearranged) {
    if (isRearranged) {
      return _buildRearrangedCupsLayout(cups);
    } else {
      return _buildDefaultCupsLayout();
    }
  }

  Column _buildDefaultCupsLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCupRow(currentTeam.cups.sublist(6, 10)),
        _buildCupRow(currentTeam.cups.sublist(3, 6)),
        _buildCupRow(currentTeam.cups.sublist(1, 3)),
        _buildCupRow(currentTeam.cups.sublist(0, 1)),
      ],
    );
  }

  Column _buildRearrangedCupsLayout(List<Cup> cups) {
    List<Row> cupRows = [];

    switch (cups.length) {
      case 6:
        cupRows.add(_buildCupRow(cups.sublist(0, 3)));
        cupRows.add(_buildCupRow(cups.sublist(3, 5)));
        cupRows.add(_buildCupRow(cups.sublist(5, 6)));
        break;
      case 5:
        cupRows.add(_buildCupRow(cups.sublist(0, 1)));
        cupRows.add(_buildCupRow(cups.sublist(1, 3)));
        cupRows.add(_buildCupRow(cups.sublist(3, 4)));
        cupRows.add(_buildCupRow(cups.sublist(4, 5)));
        break;
      case 4:
        cupRows.add(_buildCupRow(cups.sublist(0, 1)));
        cupRows.add(_buildCupRow(cups.sublist(1, 3)));
        cupRows.add(_buildCupRow(cups.sublist(3, 4)));
        break;
      case 3:
        cupRows.add(_buildCupRow(cups.sublist(0, 2)));
        cupRows.add(_buildCupRow(cups.sublist(2, 3)));
        break;
      case 2:
        cupRows.add(_buildCupRow(cups.sublist(0, 2)));
        break;
      default:
        cupRows.add(_buildCupRow(cups.sublist(0, 1)));
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cupRows,
    );
  }

  Future<void> _showRearrangeErrorDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rearrange Error'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You can only rearrange if you have 6 or fewer cups.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Cup> _assignSpecificIndices(List<Cup> cups) {
    List<int> newIndices = [];
    switch (cups.length) {
      case 6:
        newIndices = [6, 7, 8, 3, 4, 1];
        break;
      case 5:
        newIndices = [7, 3, 4, 1, 0];
        break;
      case 4:
        newIndices = [7, 3, 4, 1];
        break;
      case 3:
        newIndices = [7, 8, 4];
        break;
      case 2:
        newIndices = [7, 3];
        break;
      case 1:
        newIndices = [7];
        break;
      default:
        newIndices = List.generate(cups.length, (index) => index);
    }

    for (int i = 0; i < cups.length; i++) {
      cups[i] =
          Cup(index: newIndices[i], color: cups[i].color, isVisible: true);
    }
    return cups;
  }

  Row _buildCupRow(List<Cup> cups) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cups.map((cup) {
        return cup.widget(() => islandShotActive
            ? _handleIslandShot(cup.index)
            : _showPlayerSelectionDialog(context, cup.index));
      }).toList(),
    );
  }

  Widget _buildCurrentGamePage() {
    return Stack(
      children: [
        Positioned(
          top: 90.0,
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
              border: Border.all(
                color: Colors.white,
                width: 4.0,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    backgroundColor: Colors.amber,
                    heroTag: "airball",
                    onPressed: () => _showAirballPlayerSelectionDialog(context),
                    tooltip: 'Airball',
                    label: const Text('Airball'),
                    icon: const Icon(BeerpongIcons.airball, size: 45),
                  ),
                ],
              ),
              currentTeam.isRearranged
                  ? _buildCups(currentTeam.remainingCups, true)
                  : _buildCups(currentTeam.cups, false),
              const SizedBox(height: 40),
              Text(currentTeam.currentPlayers[0].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              Text(currentTeam.currentPlayers[1].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              _buildSpecialRulesButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRulesButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (selectedRules["Deathcup"] == true)
          FloatingActionButton(
            onPressed: () => _showDeathcupSelectionDialog(context),
            backgroundColor: Colors.amber,
            heroTag: "Deathcup",
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                    topLeft: Radius.circular(100))),
            child: const Icon(BeerpongIcons.skull, size: 35),
          ),
        Visibility(
          visible: selectedRules["Island"] == true,
          child: FloatingActionButton(
            backgroundColor: islandBackgroundColor,
            heroTag: "Island",
            onPressed: currentTeam.canIslandShot &&
                    currentTeam.cups.any(
                        (element) => element.isVisible && _isIslandCup(element))
                ? () {
                    _highlightIslandCups();
                  }
                : () {}, // Disable the button if the conditions are not met
            child: const Icon(BeerpongIcons.palm_tree, size: 45),
          ),
        )
      ],
    );
  }

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
                'Team Statistic',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(
                color: Colors.amber,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              DataTable(
                columns: const [
                  DataColumn(
                      label: Text('Player',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('S', style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('M', style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('T', style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('A', style: TextStyle(color: Colors.white))),
                ],
                rows: currentTeam.currentPlayers.map((player) {
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Icon(Icons.person, color: teamColor),
                        const SizedBox(width: 8),
                        Text(player.name,
                            style: const TextStyle(color: Colors.white)),
                      ],
                    )),
                    DataCell(Text('${player.score}',
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text('${player.misses}',
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text('${player.throws}',
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text('${player.airballs}',
                        style: const TextStyle(color: Colors.white))),
                  ]);
                }).toList(),
              ),
              const SizedBox(height: 50),
              _buildHitRateChart(teamColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHitRateChart(Color teamColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hit Rate (%)',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(
          color: Colors.amber,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: currentTeam.currentPlayers.length,
            itemBuilder: (context, index) {
              final player = currentTeam.currentPlayers[index];
              final hitRate = _calculateHitRate(player.score, player.throws);
              return Column(
                children: [
                  Text(player.name,
                      style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: CircularPercentIndicator(
                      radius: 50.0,
                      lineWidth: 10.0,
                      animation: true,
                      percent: hitRate / 1000,
                      center: Text(
                        "${hitRate.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          color: teamColor,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: teamColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FloatingActionButton(
            backgroundColor: Colors.amber,
            heroTag: "undo",
            onPressed: _undoLastAction,
            tooltip: 'Rückgängig',
            child: const Icon(Icons.undo),
          ),
          FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            heroTag: "rearrange",
            onPressed: toggleRearranged,
            tooltip: 'Verbleibende Becker umstellen.',
            label: const Text('Umstellen'),
            icon: const Icon(BeerpongIcons.umstellen, size: 35),
          ),
          FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            heroTag: "end",
            onPressed: () => _confirmEndTurn(context),
            tooltip:
                'Die getroffenen Becher wurden ausgewählt. Gegnerischer Zug.',
            label: const Text('Zugende'),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}
