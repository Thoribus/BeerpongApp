import 'package:flutter/material.dart';
import '../models/cup.dart';
import '../models/player.dart';
import '../models/game_statistics.dart';
import 'dart:math';
import '../database_helper.dart';

// GameScreen is a stateful widget that represents the main page of the application.
class GameScreen extends StatefulWidget {
  const GameScreen(
      {super.key,
      required this.title,
      required this.players1,
      required this.players2});

  final String title; // The title of the page
  final List<Player>
      players1; // List of players in Team 1 participating in the game
  final List<Player>
      players2; // List of players in Team 2 participating in the game

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// _GameScreenState is the state for GameScreen, managing its state and behavior.
class _GameScreenState extends State<GameScreen> {
  // Initializing players based on the provided list of players
  late List<Player> team1Players = widget.players1;
  late List<Player> team2Players = widget.players2;

  // Initializing cups for both teams
  List<Cup> team1Cups = List.generate(10, (index) => Cup(index));
  List<Cup> team2Cups = List.generate(10, (index) => Cup(index));

  bool isTeamOneTurn = true; // Boolean to track whose turn it is
  bool isRearranged =
      false; // Boolean to track if the cups have been rearranged

  late List<Player> currentPlayers; // List of players for the current turn
  late List<Cup> currentCups; // List of cups for the current turn

  List<GameStatistics> gameStatisticsList = []; // List to store game statistics
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // Initialize the current players and cups
    currentPlayers = isTeamOneTurn ? team1Players : team2Players;
    currentCups = isTeamOneTurn ? team2Cups : team1Cups;
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
                    _addCupToPlayer(player, cupIndex);
                    _handleCupHit(cupIndex);
                    _incrementPlayerScore(player);
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
      _checkGameEnd(); // Check if the game has ended
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
    if (currentCups.every((cup) => cup.isVisible && cup.color == Colors.red) &&
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
      }

      for (var cup in currentCups) {
        if (cup.color == Colors.green) cup.isVisible = false;
      }

      // Switch turn to the other team
      isTeamOneTurn = !isTeamOneTurn;
      currentPlayers = isTeamOneTurn ? team1Players : team2Players;
      currentCups = isTeamOneTurn ? team2Cups : team1Cups;
    });
  }

  // Function to calculate the distance between two points
  double _calculateDistance(Offset position1, Offset position2) {
    return sqrt(pow(position1.dx - position2.dx, 2) +
        pow(position1.dy - position2.dy, 2));
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
    currentCups[index].color = Colors.red;
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
  void _checkGameEnd() async {
    bool teamAllHit =
        currentCups.every((cup) => !cup.isVisible || cup.color == Colors.green);

    if (teamAllHit) {
      _saveGameStatistics();
      _showGameEndDialog(currentPlayers);
    }
  }

  void _saveGameStatistics() async {
    String winningTeam =
        team1Cups.every((cup) => !cup.isVisible) ? "Team 2" : "Team 1";

    GameStatistics stats = GameStatistics(
      date: DateTime.now(),
      team1Players: List.from(team1Players),
      team2Players: List.from(team2Players),
      winningTeam: winningTeam,
    );

    await _dbHelper.insertGame(stats);

    setState(() {
      gameStatisticsList.add(stats);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FloatingActionButton.extended(
                heroTag: "airball",
                onPressed: _showAirballPlayerSelectionDialog,
                tooltip: 'Airball',
                label: const Text('Airball'),
                icon: const Icon(Icons.air_rounded),
              ),
            ]),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rows of cups for both teams, displayed conditionally based on whose turn it is
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  currentCups[6].widget(() => _showPlayerSelectionDialog(6)),
                  currentCups[7].widget(() => _showPlayerSelectionDialog(7)),
                  currentCups[8].widget(() => _showPlayerSelectionDialog(8)),
                  currentCups[9].widget(() => _showPlayerSelectionDialog(9)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  currentCups[3].widget(() => _showPlayerSelectionDialog(3)),
                  currentCups[4].widget(() => _showPlayerSelectionDialog(4)),
                  currentCups[5].widget(() => _showPlayerSelectionDialog(5)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  currentCups[1].widget(() => _showPlayerSelectionDialog(1)),
                  currentCups[2].widget(() => _showPlayerSelectionDialog(2)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  currentCups[0].widget(() => _showPlayerSelectionDialog(0)),
                ]),
              ],
            ),
            // Displaying the scores and misses of each player
            ...currentPlayers.map((player) {
              return Text(
                '${player.name} Score: ${player.score} Misses: ${player.misses}',
                style: Theme.of(context).textTheme.headlineSmall,
              );
            }),
            // Displaying the current team
            Text(
              'Current Team: ${isTeamOneTurn ? "Team 1" : "Team 2"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "increment",
              onPressed: () => _checkProximity(4),
              tooltip: 'Increment',
              child: const Icon(Icons.scatter_plot_outlined),
            ),
            FloatingActionButton.extended(
                heroTag: "miss",
                onPressed: () => {isRearranged = !isRearranged},
                tooltip: 'Kein Becher wurde diese Runde getroffen.',
                label: const Text('Kein Treffer'),
                icon: const Icon(Icons.clear_rounded)),
            FloatingActionButton.extended(
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
}
