import 'package:beerpongapp/firestoreservice.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import '../models/cup.dart';
import '../models/player.dart';
import '../models/game_statistics.dart';
import 'dart:math';
import '../database_helper.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/user.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.title,
    required this.players1,
    required this.players2,
    required this.selectedRules,
  });

  final String title;
  final List<Player> players1;
  final List<Player> players2;
  final Map<String, bool> selectedRules;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Player> team1Players = widget.players1;
  late List<Player> team2Players = widget.players2;
  late Map<String, bool> selectedRules = widget.selectedRules;

  final Color team1Color = Colors.blue;
  final Color team2Color = Colors.red;

  List<Cup> team1Cups = [];
  List<Cup> team2Cups = [];
  bool isTeamOneTurn = true;
  bool isRearranged1 = false;
  bool isRearranged2 = false;
  bool isRearranged = false;

  late Color currentTeamColor;
  late List<Player> currentPlayers;
  late List<Cup> currentCups;
  List<Cup> remainingCups1 = [];
  List<Cup> remainingCups2 = [];

  List<GameStatistics> gameStatisticsList = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<Map<String, dynamic>> _actionStack = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _pageController.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    team1Cups =
        List.generate(10, (index) => Cup(index: index, color: team1Color));
    team2Cups =
        List.generate(10, (index) => Cup(index: index, color: team2Color));
    currentPlayers = rotatePlayers(isTeamOneTurn ? team1Players : team2Players);
    currentCups = isTeamOneTurn ? team1Cups : team2Cups;
    currentTeamColor = isTeamOneTurn ? team1Color : team2Color;
  }

  void _handlePageChange() {
    int page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _showSelectionDialog(
      String title, List<Player> players, Function(Player) onSelected) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: players.map((player) {
                return ElevatedButton(
                  child: Text(player.name),
                  onPressed: () {
                    Navigator.of(context).pop();
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

  Future<void> _showPlayerSelectionDialog(int cupIndex) async {
    await _showSelectionDialog(
      'Select Player',
      currentPlayers,
      (player) {
        _saveCurrentState();
        _addCupToPlayer(player, cupIndex);
        _handleCupHit(cupIndex);
        _incrementPlayerScore(player);
        _checkGameEnd(player);
      },
    );
  }

  Future<void> _showDeathcupSelectionDialog() async {
    await _showSelectionDialog(
      'Select Player',
      currentPlayers,
      (player) {
        _saveCurrentState();
        for (var cup in currentCups) {
          if (cup.color == currentTeamColor) {
            _addCupToPlayer(player, cup.index);
            _handleCupHit(cup.index);
            _incrementPlayerScore(player);
          }
        }
        _checkGameEnd(player);
      },
    );
  }

  Future<void> _confirmEndTurn() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('End Turn'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveCurrentState();
                _endTurn();
              },
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

  void _addCupToPlayer(Player player, int cupIndex) {
    setState(() {
      player.hitCup(cupIndex);
    });
  }

  void _handleCupHit(int index) {
    setState(() {
      if (currentCups.firstWhere((cup) => cup.index == index).color == Colors.green) {
        _checkProximity(index);
      } else {
        _checkBitchCup(index);
        currentCups.firstWhere((cup) => cup.index == index).color = Colors.green;
      }
    });
  }

  void _checkBitchCup(int index) {
    if (currentCups
            .every((cup) => cup.isVisible && cup.color == currentTeamColor) &&
        index == 4) {
      _showBitchCupDialog();
    }
  }

  Future<void> _showBitchCupDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _endTurn() {
    setState(() {
      for (var player in currentPlayers) {
        if (!player.hitThisRound) {
          player.incrementMisses();
        }
        player.resetHitThisRound();
        player.incrementThrows();
      }

      for (var cup in currentCups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }

      isTeamOneTurn = !isTeamOneTurn;
      currentPlayers =
          rotatePlayers(isTeamOneTurn ? team1Players : team2Players);
      currentTeamColor = isTeamOneTurn ? team1Color : team2Color;
      currentCups = isTeamOneTurn ? team1Cups : team2Cups;
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

  List<Player> rotatePlayers(List<Player> players) {
    if (players.length <= 2) return players;

    Player player1 = players.removeAt(0);
    Player player2 = players.removeAt(0);
    players.add(player1);
    players.add(player2);

    return players.sublist(0, 2);
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
        _buildCupRow(currentCups.sublist(6, 10)),
        _buildCupRow(currentCups.sublist(3, 6)),
        _buildCupRow(currentCups.sublist(1, 3)),
        _buildCupRow(currentCups.sublist(0, 1)),
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
        cupRows.add(_buildCupRow(cups.sublist(0, 3)));
        cupRows.add(_buildCupRow(cups.sublist(3, 5)));
        break;
      case 4:
        cupRows.add(_buildCupRow(cups.sublist(0, 2)));
        cupRows.add(_buildCupRow(cups.sublist(2, 4)));
        break;
      case 3:
        cupRows.add(_buildCupRow(cups.sublist(0, 2)));
        cupRows.add(_buildCupRow(cups.sublist(2, 3)));
        break;
      case 2:
        cupRows.add(_buildCupRow(cups.sublist(0, 2)));
        break;
      case 1:
        cupRows.add(_buildCupRow(cups.sublist(0, 1)));
        break;
      default:
        cupRows.add(_buildCupRow(cups.sublist(0, 3)));
        cupRows.add(_buildCupRow(cups.sublist(3, 4)));
        cupRows.add(_buildCupRow(cups.sublist(4, 6)));
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cupRows,
    );
  }

  Row _buildCupRow(List<Cup> cups) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cups.map((cup) {
        return cup.widget(() => _showPlayerSelectionDialog(cup.index));
      }).toList(),
    );
  }

  double _calculateDistance(Offset position1, Offset position2) {
    return sqrt(pow(position1.dx - position2.dx, 2) +
        pow(position1.dy - position2.dy, 2));
  }

  double _calculateHitRate(double score, int throws) {
    if (throws == 0) return 0.0;
    return (score / throws) * 100;
  }

  void _checkProximity(int index) {
    const double proximityThreshold = 100.0;
    double hitCups = 0.0;

    for (int i = 0; i < currentCups.length; i++) {
      if (i == index) continue;
      if (currentCups[i].isVisible && currentCups[index].isVisible) {
        final renderBox1 =
            currentCups[i].key.currentContext?.findRenderObject() as RenderBox?;
        final renderBox2 = currentCups[index]
            .key
            .currentContext
            ?.findRenderObject() as RenderBox?;

        if (renderBox1 != null && renderBox2 != null) {
          Offset position1 = renderBox1.localToGlobal(Offset.zero);
          Offset position2 = renderBox2.localToGlobal(Offset.zero);

          double distance = _calculateDistance(position1, position2);
          if (distance < proximityThreshold) {
            hitCups++;
            currentCups[i].color = Colors.green;
          }
        }
      }
    }
    currentCups[index].color = currentTeamColor;
    for (var player in currentPlayers) {
      if (player.cupsHit.contains(index)) {
        player.incrementScoreBy(hitCups / 2 - 1);
      }
    }
  }

  Future<void> _showAirballPlayerSelectionDialog() async {
    await _showSelectionDialog(
      'Select Player',
      currentPlayers,
      (player) {
        _saveCurrentState();
        _incrementPlayerAirballs(player);
      },
    );
  }

  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      int teamAirballs =
          currentPlayers.fold(0, (sum, player) => sum + player.airballs);
      if (teamAirballs % 3 == 0) {
        _showAirballDialog(teamAirballs);
      }
    });
  }

  void _checkGameEnd(Player player) async {
    bool teamAllHit =
        currentCups.every((cup) => !cup.isVisible || cup.color == Colors.green);

    if (teamAllHit) {
      _setPlayerHitLastCup(player);
      await _saveGameStatistics();
      _showGameEndDialog(currentPlayers);
    }
  }

  Future<void> _saveGameStatistics() async {
    bool blueTeamWin = team1Cups.every((cup) => !cup.isVisible) ? false : true;

    void updatePlayers(Player player) {
      if (player.user != null) {
        User updatedUser = player.user!;
        if (blueTeamWin) {
          updatedUser.wins++;
        } else {
          updatedUser.losses++;
        }
        updatedUser.totalAirballs += player.airballs;
        updatedUser.totalMisses += player.misses;
        updatedUser.totalThrows += player.throws;
        updatedUser.totalScore += player.score;
        updatedUser.cupsHit.addAll(player.cupsHit);
        FirestoreService().updateUser(updatedUser);
      }
    }

    GameStatistics stats = GameStatistics(
      date: DateTime.now(),
      team1Players: List.from(team1Players),
      team2Players: List.from(team2Players),
      winningTeam: blueTeamWin ? "Team 2" : "Team 1",
    );

    for (var player in team1Players) {
      updatePlayers(player);
    }
    for (var player in team2Players) {
      updatePlayers(player);
    }

    await _dbHelper.insertGame(stats);

    setState(() {
      gameStatisticsList.add(stats);
    });
  }

  void _saveCurrentState() {
    _actionStack.add({
      'team1Cups': team1Cups.map((cup) => cup.clone()).toList(),
      'team2Cups': team2Cups.map((cup) => cup.clone()).toList(),
      'team1Players': team1Players.map((player) => player.clone()).toList(),
      'team2Players': team2Players.map((player) => player.clone()).toList(),
      'isTeamOneTurn': isTeamOneTurn,
      'isRearranged1': isRearranged1,
      'isRearranged2': isRearranged2,
    });
  }

  void _undoLastAction() {
    if (_actionStack.isEmpty) return;

    final lastState = _actionStack.removeLast();
    setState(() {
      team1Cups = lastState['team1Cups'].cast<Cup>();
      team2Cups = lastState['team2Cups'].cast<Cup>();
      team1Players = lastState['team1Players'].cast<Player>();
      team2Players = lastState['team2Players'].cast<Player>();
      isTeamOneTurn = lastState['isTeamOneTurn'];
      isRearranged1 = lastState['isRearranged1'];
      isRearranged2 = lastState['isRearranged2'];
      currentPlayers = isTeamOneTurn ? team1Players : team2Players;
      currentCups = isTeamOneTurn ? team1Cups : team2Cups;
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

  Future<void> _showGameEndDialog(List<Player> players) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('${players[0].name} and ${players[1].name} won!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAirballDialog(int airballs) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color teamColor = isTeamOneTurn ? Colors.blue : Colors.red;

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
      body: Column(
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
                    color: _currentPage == 0 ? Colors.amber : Colors.white,
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
                    color: _currentPage == 1 ? Colors.amber : Colors.white,
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
                _buildGameStatsPage(teamColor),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAppBar(),
      backgroundColor: Colors.black,
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
                    onPressed: _showAirballPlayerSelectionDialog,
                    tooltip: 'Airball',
                    label: const Text('Airball'),
                    icon: const Icon(BeerpongIcons.airball, size: 45),
                  ),
                ],
              ),
              isRearranged
                  ? (isTeamOneTurn
                      ? _buildCups(remainingCups1, true)
                      : _buildCups(remainingCups2, true))
                  : _buildCups(currentCups, false),
              const SizedBox(height: 40),
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
            onPressed: _showDeathcupSelectionDialog,
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
        if (selectedRules["Island"] == true)
          FloatingActionButton(
            backgroundColor: Colors.amber,
            heroTag: "Island",
            onPressed: () {
              print('Button 2 Pressed');
            },
            child: const Icon(BeerpongIcons.palmtree, size: 45),
          ),
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
                rows: currentPlayers.map((player) {
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
            itemCount: currentPlayers.length,
            itemBuilder: (context, index) {
              final player = currentPlayers[index];
              final hitRate = _calculateHitRate(player.score, player.throws);
              return Column(
                children: [
                  Text(player.name, style: TextStyle(color: Colors.white)),
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
            heroTag: "increment",
            onPressed: _undoLastAction,
            tooltip: 'Increment',
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
            onPressed: _confirmEndTurn,
            tooltip:
                'Die getroffenen Becher wurden ausgewählt. Gegnerischer Zug.',
            label: const Text('Zugende'),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }

  void _setPlayerHitLastCup(Player player) {
    setState(() {
      player.hitLastCup();
    });
  }

  void toggleRearranged() {
    if (currentCups.where((cup) => cup.isVisible).length > 6) {
      _showRearrangeErrorDialog();
      return;
    }

    _saveCurrentState();

    setState(() {
      if (isTeamOneTurn) {
        if (!isRearranged1) {
          remainingCups1 = currentCups
              .where((cup) => cup.isVisible && cup.color == team1Color)
              .toList();
          remainingCups1 = _assignSpecificIndices(remainingCups1);
          currentCups = remainingCups1;
          team1Cups = remainingCups1;
          isRearranged1 = true;
        }
      } else {
        if (!isRearranged2) {
          remainingCups2 = currentCups
              .where((cup) => cup.isVisible && cup.color == team2Color)
              .toList();
          remainingCups2 = _assignSpecificIndices(remainingCups2);
          currentCups = remainingCups2;
          team2Cups = remainingCups2;
          isRearranged2 = true;
        }
      }
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

    // Function to show the rearrange error dialog
  Future<void> _showRearrangeErrorDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Helper method to assign specific indices based on the new layout
  List<Cup> _assignSpecificIndices(List<Cup> cups) {
    List<int> newIndices = [];
    switch (cups.length) {
      case 6:
        newIndices = [6, 7, 8, 3, 4, 1];
        break;
      case 5:
        newIndices = [6, 7, 8, 3, 4];
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
}
