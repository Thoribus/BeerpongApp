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

  late bool isTeamOneTurn = widget.startingTeam;
  bool islandShotActive = false;

  List<GameStatistics> gameStatisticsList = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<Map<String, dynamic>> _actionStack = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late Future<void> _loadGameFuture;

  @override
  void initState() {
    super.initState();
    _loadGameFuture = _loadGameState();
    _pageController.addListener(_handlePageChange);
  }

  void _initializeGame() {
    team1 = Team(
      color: Colors.blue,
      players: widget.players1,
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.blue)),
    );
    team2 = Team(
      color: Colors.red,
      players: widget.players2,
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.red)),
    );
    
    currentTeam = isTeamOneTurn ? team1 : team2;
    currentTeam.currentPlayers = currentTeam.rotatePlayers();
  }

  @override
  void dispose() {
    super.dispose();
    _saveGameState();
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
      currentTeam.players,
      (player) {
        _saveCurrentState();
        _addCupToPlayer(player, cupIndex);
        _handleCupHit(cupIndex);
        _incrementPlayerScore(player);
        _checkGameEnd(player);
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
          }
        }
        _checkGameEnd(player);
      },
    );
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
      if (currentTeam.cups.firstWhere((cup) => cup.index == index).color ==
          Colors.green) {
        _checkProximity(index);
      } else {
        _checkBitchCup(index);
        currentTeam.cups.firstWhere((cup) => cup.index == index).color =
            Colors.green;
      }
    });
  }

  void _checkBitchCup(int index) {
    if (currentTeam.cups
            .every((cup) => cup.isVisible && cup.color == currentTeam.color) &&
        index == 4) {
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

  void _endTurn() {
    setState(() {
      for (var player in currentTeam.currentPlayers) {
        if (!player.hitThisRound) {
          player.incrementMisses();
        }
        player.resetHitThisRound();
        player.incrementThrows();
      }

      for (var cup in currentTeam.cups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }

      isTeamOneTurn = !isTeamOneTurn;
      currentTeam = isTeamOneTurn ? team1 : team2;
      currentTeam.currentPlayers = currentTeam.rotatePlayers();
    });
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
      default:
        cupRows.add(_buildCupRow(cups.sublist(0, 1)));
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
        return cup.widget(() => islandShotActive
            ? _handleIslandShot(cup.index)
            : _showPlayerSelectionDialog(context, cup.index));
      }).toList(),
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

    for (int i = 0; i < currentTeam.cups.length; i++) {
      if (i == index) continue;
      if (currentTeam.cups[i].isVisible && currentTeam.cups[index].isVisible) {
        final renderBox1 = currentTeam.cups[i].key.currentContext
            ?.findRenderObject() as RenderBox?;
        final renderBox2 = currentTeam.cups[index].key.currentContext
            ?.findRenderObject() as RenderBox?;

        if (renderBox1 != null && renderBox2 != null) {
          Offset position1 = renderBox1.localToGlobal(Offset.zero);
          Offset position2 = renderBox2.localToGlobal(Offset.zero);

          double distance = _calculateDistance(position1, position2);
          if (distance < proximityThreshold) {
            hitCups++;
            currentTeam.cups[i].color = Colors.green;
          }
        }
      }
    }
    currentTeam.cups[index].color = currentTeam.color;
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

  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      int teamAirballs = currentTeam.currentPlayers
          .fold(0, (sum, player) => sum + player.airballs);
      if (teamAirballs % 3 == 0) {
        _showAirballDialog(context, teamAirballs);
      }
    });
  }

  void _checkGameEnd(Player player) async {
    bool teamAllHit = currentTeam.cups
        .every((cup) => !cup.isVisible || cup.color == Colors.green);

    if (teamAllHit) {
      _setPlayerHitLastCup(player);
      await _clearGameState();
      await _saveGameStatistics();
      _showGameEndDialog(context, currentTeam.currentPlayers);
    }
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

  Future<void> _saveGameStatistics() async {
    bool blueTeamWin = team1.cups.every((cup) => !cup.isVisible) ? false : true;

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
      team1Players: List.from(team1.players),
      team2Players: List.from(team2.players),
      winningTeam: blueTeamWin ? "Team 2" : "Team 1",
    );

    for (var player in team1.players) {
      updatePlayers(player);
    }
    for (var player in team2.players) {
      updatePlayers(player);
    }

    await _dbHelper.insertGame(stats);

    setState(() {
      gameStatisticsList.add(stats);
    });
  }

  void _saveCurrentState() {
    _actionStack.add({
      'team1Cups': team1.cups.map((cup) => cup.clone()).toList(),
      'team2Cups': team2.cups.map((cup) => cup.clone()).toList(),
      'team1Players': team1.players.map((player) => player.clone()).toList(),
      'team2Players': team2.players.map((player) => player.clone()).toList(),
      'isTeamOneTurn': isTeamOneTurn,
      'isRearranged1': team1.isRearranged,
      'isRearranged2': team2.isRearranged,
    });
  }

  void _undoLastAction() {
    if (_actionStack.isEmpty) return;

    final lastState = _actionStack.removeLast();
    setState(() {
      team1.cups = lastState['team1Cups'].cast<Cup>();
      team2.cups = lastState['team2Cups'].cast<Cup>();
      team1.players = lastState['team1Players'].cast<Player>();
      team2.players = lastState['team2Players'].cast<Player>();
      isTeamOneTurn = lastState['isTeamOneTurn'];
      team1.isRearranged = lastState['isRearranged1'];
      team2.isRearranged = lastState['isRearranged2'];
      currentTeam = isTeamOneTurn ? team1 : team2;
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
                Text('${players[0].name} and ${players[1].name} won!'),
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
      body: FutureBuilder<void>(
        future: _loadGameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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
                      _buildGameStatsPage(teamColor),
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
        if (selectedRules["Island"] == true && currentTeam.canIslandShot)
          FloatingActionButton(
            backgroundColor: Colors.amber,
            heroTag: "Island",
            onPressed: () {
              _highlightIslandCups();
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

  void _highlightIslandCups() {
    setState(() {
      islandShotActive = true;
      for (var cup in currentTeam.cups) {
        if (_isIslandCup(cup)) {
          cup.color = Colors.yellow;
        }
      }
    });
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

  Future<void> _handleIslandShot(int cupIndex) async {
    await _showSelectionDialog(
      context,
      'Select Player and Shot Result',
      currentTeam.currentPlayers
          .where((player) => player.islandShotUsed == false)
          .toList(),
      (player) {
        _saveCurrentState();
        _addCupToPlayer(player, cupIndex);
        _incrementPlayerScore(player);
        _handleCupHit(cupIndex);
        _incrementPlayerScore(player);
        _handleCupHit(currentTeam.cups
            .firstWhere((cup) =>
                cup.index != cupIndex && cup.color == currentTeam.color)
            .index);

        setState(() {
          player.islandShotUsed = true;
          if (currentTeam.currentPlayers
              .every((player) => player.islandShotUsed == true)) {
            currentTeam.canIslandShot = false;
          }
          islandShotActive = false;
        });
      },
    );
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
    });
  }
}
