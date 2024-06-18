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

// GameScreen is a stateful widget that represents the main page of the application.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.title,
    required this.players1,
    required this.players2,
    required this.selectedRules,
  });

  final String title; // The title of the page
  final List<Player>
      players1; // List of players in Team 1 participating in the game
  final List<Player>
      players2; // List of players in Team 2 participating in the game
  final Map<String, bool> selectedRules; // Map of selected special rules

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// _GameScreenState is the state for GameScreen, managing its state and behavior.
class _GameScreenState extends State<GameScreen> {
  // Initializing players based on the provided list of players
  late List<Player> team1Players = widget.players1;
  late List<Player> team2Players = widget.players2;
  late Map<String, bool> selectedRules = widget.selectedRules;

  Color team1Color = Colors.blue; // Color for Team 1
  Color team2Color = Colors.red; // Color for Team 2

  // Initializing cups for both teams
  List<Cup> team1Cups = [];
  List<Cup> team2Cups = [];

  bool isTeamOneTurn = true; // Boolean to track whose turn it is
  bool isRearranged1 =
      false; // Boolean to track if the cups have been rearranged
  bool isRearranged2 = false;
  bool isRearranged = false;

  late Color currentTeamColor; // Color for the current team
  late List<Player> currentPlayers; // List of players for the current turn
  late List<Cup> currentCups; // List of cups for the current turn
  List<Cup> remainingCups1 = [];
  List<Cup> remainingCups2 = [];

  List<GameStatistics> gameStatisticsList = []; // List to store game statistics
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Stack to keep track of the previous states
  List<Map<String, dynamic>> _actionStack = [];

  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the current players and cups
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    team1Cups =
        List.generate(10, (index) => Cup(index: index, color: team1Color));
    team2Cups =
        List.generate(10, (index) => Cup(index: index, color: team2Color));
    currentPlayers = rotatePlayers(isTeamOneTurn ? team1Players : team2Players);
    currentCups = isTeamOneTurn ? team1Cups : team2Cups;
    currentTeamColor = isTeamOneTurn ? team1Color : team2Color;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void toggleRearranged() {
    _saveCurrentState();

    setState(() {
      if (isTeamOneTurn) {
        if (!isRearranged1) {
          remainingCups1 = currentCups
              .where((cup) => cup.isVisible && cup.color == team1Color)
              .toList();
          isRearranged1 = true;
        }
      } else {
        if (!isRearranged2) {
          remainingCups2 = currentCups
              .where((cup) => cup.isVisible && cup.color == team2Color)
              .toList();
          isRearranged2 = true;
        }
      }
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

  // Function to show player selection dialog
  Future<void> _showPlayerSelectionDialog(int cupIndex) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Player'),
          content: SingleChildScrollView(
            child: ListBody(
              children: currentPlayers.map((player) {
                return ElevatedButton(
                  child: Text(player.name),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveCurrentState();
                    _addCupToPlayer(player, cupIndex);
                    _handleCupHit(cupIndex);
                    _incrementPlayerScore(player);
                    _checkGameEnd(player); // Check if the game has ended
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

   // Function to show player selection dialog
  _showDeathcupSelectionDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Player'),
          content: SingleChildScrollView(
            child: ListBody(
              children: currentPlayers.map((player) {
                return ElevatedButton(
                  child: Text(player.name),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveCurrentState();
                    for (var cup in currentCups) {
                      if (cup.color == currentTeamColor) {
                        _addCupToPlayer(player, cup.index);
                        _handleCupHit(cup.index);
                        _incrementPlayerScore(player);
                      }
                    }
                    _checkGameEnd(player); // Check if the game has ended
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Function to confirm ending the turn
  Future<void> _confirmEndTurn() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
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
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('End Turn'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _saveCurrentState();
                _endTurn(); // End the turn
              },
            ),
          ],
        );
      },
    );
  }

  // Function to increment the player's score
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

  // Function to handle a cup being hit
  void _handleCupHit(int index) {
    setState(() {
      if (currentCups[index].color == Colors.green) {
        _checkProximity(index);
      } else {
        _checkBitchCup(index);
        currentCups[index].color = Colors.green;
      }
    });
  }

  // Function to check the special condition for "Bitchcup"
  void _checkBitchCup(int index) {
    // Check if every cup is visible and red, and the index is 4 (the Bitchcup index)
    if (currentCups
            .every((cup) => cup.isVisible && cup.color == currentTeamColor) &&
        index == 4) {
      _showBitchCupDialog();
    }
  }

  // Function to show the "Bitchcup" dialog
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to end the turn
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

      // Switch turn to the other team
      isTeamOneTurn = !isTeamOneTurn;
      currentPlayers =
          rotatePlayers(isTeamOneTurn ? team1Players : team2Players);
      currentTeamColor = isTeamOneTurn ? team1Color : team2Color;
      currentCups = isTeamOneTurn ? team1Cups : team2Cups;
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

  List<Player> rotatePlayers(List<Player> players) {
    // Ensure there are at least two players to rotate
    if (players.length <= 2) return players;

    print(players);

    Player player1 = players.removeAt(0);
    Player player2 = players.removeAt(0);
    players.add(player1);
    players.add(player2);
    print(players.sublist(0, 2));

    return players.sublist(0, 2);
  }

  Column _buildCups(List<Cup> cups) {
    switch (cups.length) {
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 3).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(3, 5).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(5, 6).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 3).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(3, 5).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 1).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(1, 3).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(3, 4).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 2).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(2, 3).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 1).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(1, 2).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 1).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rows of cups for both teams, displayed conditionally based on whose turn it is
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(0, 3).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(3, 4).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...cups.sublist(4, 6).map((cup) {
                return cup.widget(() => _showPlayerSelectionDialog(cup.index));
              }),
            ]),
          ],
        );
    }
  }

  // Function to calculate the distance between two points
  double _calculateDistance(Offset position1, Offset position2) {
    return sqrt(pow(position1.dx - position2.dx, 2) +
        pow(position1.dy - position2.dy, 2));
  }

  // Function to calculate hit rate as a ratio from throws and hits
  double _calculateHitRate(double score, int throws) {
    if (throws == 0) return 0.0;
    return (score / throws) * 100;
  }

  // Function to check the proximity of cups
  void _checkProximity(int index) {
    const double proximityThreshold = 100.0; // Adjust as needed
    double hitCups = 0.0;

    for (int i = 0; i < currentCups.length; i++) {
      if (i == index) continue;
      if (currentCups[i].isVisible && currentCups[index].isVisible) {
        // Get the positions of the cups
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
    print(hitCups);
    for (var player in currentPlayers) {
      if (player.cupsHit.contains(index)) {
        player.incrementScoreBy(hitCups / 2 - 1);
      }
    }
  }

  // Function to show the airball player selection dialog
  Future<void> _showAirballPlayerSelectionDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Player'),
          content: SingleChildScrollView(
            child: ListBody(
              children: currentPlayers.map((player) {
                return ElevatedButton(
                  child: Text(player.name),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveCurrentState();
                    _incrementPlayerAirballs(player);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Function to increment the player's airballs
  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      print("Airball for ${player.name} total: ${player.airballs}");
      int teamAirballs =
          currentPlayers.fold(0, (sum, player) => sum + player.airballs);
      if (teamAirballs % 3 == 0) {
        _showAirballDialog(teamAirballs);
      }
    });
  }

  // Function to check if the game has ended
  void _checkGameEnd(player) async {
    bool teamAllHit =
        currentCups.every((cup) => !cup.isVisible || cup.color == Colors.green);

    if (teamAllHit) {
      _setPlayerHitLastCup(player);
      _saveGameStatistics();
      _showGameEndDialog(currentPlayers);
    }
  }

  void _saveGameStatistics() async {
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
    print(_actionStack.length);
    print(_actionStack.last);
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
      currentCups = isTeamOneTurn ? team2Cups : team1Cups;
      isRearranged = isTeamOneTurn ? isRearranged1 : isRearranged2;
    });
  }

  // Function to show the game end dialog
  Future<void> _showGameEndDialog(List<Player> players) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show the airball dialog
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // The build method describes the part of the user interface represented by this widget.
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
            onPressed: () {
              print('Beer Icon Pressed');
            },
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
                // First Page: Current Game State
                Stack(
                  children: [
                    // Gradient rectangle shape in the background
                    Positioned(
                      top: 90.0,
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          gradient: LinearGradient(
                            colors: [
                              Colors.brown.shade700,
                              Colors.brown.shade400
                            ],
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
                    // Main content
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
                                icon:
                                    const Icon(BeerpongIcons.airball, size: 45),
                              ),
                            ],
                          ),
                          isRearranged
                              ? (isTeamOneTurn
                                  ? _buildCups(remainingCups1)
                                  : _buildCups(remainingCups2))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    // Rows of cups for both teams, displayed conditionally based on whose turn it is
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        currentCups[6].widget(() =>
                                            _showPlayerSelectionDialog(6)),
                                        currentCups[7].widget(() =>
                                            _showPlayerSelectionDialog(7)),
                                        currentCups[8].widget(() =>
                                            _showPlayerSelectionDialog(8)),
                                        currentCups[9].widget(() =>
                                            _showPlayerSelectionDialog(9)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        currentCups[3].widget(() =>
                                            _showPlayerSelectionDialog(3)),
                                        currentCups[4].widget(() =>
                                            _showPlayerSelectionDialog(4)),
                                        currentCups[5].widget(() =>
                                            _showPlayerSelectionDialog(5)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        currentCups[1].widget(() =>
                                            _showPlayerSelectionDialog(1)),
                                        currentCups[2].widget(() =>
                                            _showPlayerSelectionDialog(2)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        currentCups[0].widget(() =>
                                            _showPlayerSelectionDialog(0)),
                                      ],
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 40),
                          // Add three round buttons here
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (selectedRules["Deathcup"] != null &&
                                  selectedRules["Deathcup"]!)
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
                                  child:
                                      const Icon(BeerpongIcons.skull, size: 35),
                                ),
                              if (selectedRules["Island"] != null &&
                                  selectedRules["Island"]!)
                                FloatingActionButton(
                                  backgroundColor: Colors.amber,
                                  heroTag: "Island",
                                  onPressed: () {
                                    print('Button 2 Pressed');
                                  },
                                  child: const Icon(BeerpongIcons.palmtree,
                                      size: 45),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Second Page: DataTable and Radial Bar Chart
                Container(
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
                                  label: Text('S',
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text('M',
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text('T',
                                      style: TextStyle(color: Colors.white))),
                              DataColumn(
                                  label: Text('A',
                                      style: TextStyle(color: Colors.white))),
                            ],
                            rows: currentPlayers.map((player) {
                              return DataRow(cells: [
                                DataCell(Row(
                                  children: [
                                    Icon(Icons.person, color: teamColor),
                                    const SizedBox(width: 8),
                                    Text(player.name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ],
                                )),
                                DataCell(Text('${player.score}',
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${player.misses}',
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${player.throws}',
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${player.airballs}',
                                    style: const TextStyle(
                                        color: Colors.white))), // Empty column
                              ]);
                            }).toList(),
                          ),
                          const SizedBox(height: 50),
                          Column(
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
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: currentPlayers.length,
                                  itemBuilder: (context, index) {
                                    final player = currentPlayers[index];
                                    final hitRate = _calculateHitRate(
                                        player.score, player.throws);
                                    return Column(
                                      children: [
                                        Text(
                                          player.name,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Expanded(
                                          child: CircularPercentIndicator(
                                            radius: 50.0,
                                            lineWidth: 10.0,
                                            animation: true,
                                            percent: hitRate /
                                                1000, // 1000 when percent bigger than 100 gives error in buildung the chart
                                            center: Text(
                                              "${hitRate.toStringAsFixed(1)}%",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.0,
                                                  color: teamColor),
                                            ),
                                            circularStrokeCap:
                                                CircularStrokeCap.round,
                                            progressColor: teamColor,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
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
                icon: const Icon(BeerpongIcons.umstellen, size: 35)),
            FloatingActionButton.extended(
                backgroundColor: Colors.amber,
                heroTag: "end",
                onPressed: _confirmEndTurn,
                tooltip:
                    'Die getroffenen Becher wurden ausgewählt. Gegnerischer Zug.',
                label: const Text('Zugende'),
                icon: const Icon(Icons.check_rounded)),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  void _setPlayerHitLastCup(player) {
    setState(() {
      player.hitLastCup();
      print("Player ${player.name} hit last cup!");
    });
  }
}
