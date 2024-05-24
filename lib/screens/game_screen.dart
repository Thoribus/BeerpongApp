import 'package:flutter/material.dart';
import '../models/cup.dart';
import '../models/player.dart';

// MyHomePage is a stateful widget that represents the main page of the application.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.players});

  final String title; // The title of the page
  final List<Player> players; // List of players participating in the game

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// _MyHomePageState is the state for MyHomePage, managing its state and behavior.
class _MyHomePageState extends State<MyHomePage> {
  // Initializing players based on the provided list of players
  late Player player1 = Player(widget.players[0].name);
  late Player player2 = Player(widget.players[1].name);
  late Player player3 = Player(widget.players[2].name);
  late Player player4 = Player(widget.players[3].name);

  // Initializing cups for both teams
  List<Cup> team1Cups = List.generate(10, (index) => Cup(index));
  List<Cup> team2Cups = List.generate(10, (index) => Cup(index));

  bool isTeamOneTurn = true; // Boolean to track whose turn it is

  // Function to show player selection dialog
  Future<void> _showPlayerSelectionDialog(int cupIndex) async {
    List<Player> currentPlayers =
        isTeamOneTurn ? [player1, player2] : [player3, player4];

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
                    _hideCup(cupIndex);
                    Navigator.of(context).pop();
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

  // Function to increment the player's misses
  void _incrementPlayerMisses() {
    setState(() {
      List<Player> currentPlayers =
          isTeamOneTurn ? [player1, player2] : [player3, player4];
      for (var player in currentPlayers) {
        player.incrementMisses();
      }
    });
  }

  // Function to hide a cup when it is hit
  void _hideCup(int index) {
    setState(() {
      if (isTeamOneTurn) {
        team1Cups[index].isVisible = false;
      } else {
        team2Cups[index].isVisible = false;
      }
    });
  }

  // Function to end the turn
  void _endTurn() {
    setState(() {
      List<Player> currentPlayers =
          isTeamOneTurn ? [player1, player2] : [player3, player4];

      for (var player in currentPlayers) {
        if (!player.hitThisRound) {
          player.incrementMisses();
        }
        player.resetHitThisRound();
      }

      // Switch turn to the other team
      isTeamOneTurn = !isTeamOneTurn;
    });
  }

  // Function to create the "Airball" button
  _newButtonAirball() {
    return Visibility(
        child: FloatingActionButton.extended(
            heroTag: "airball",
            onPressed: _showAirballPlayerSelectionDialog,
            tooltip: 'Airball',
            label: const Text('Airball'),
            icon: const Icon(Icons.air_rounded)));
  }

  // Function to show the airball player selection dialog
  Future<void> _showAirballPlayerSelectionDialog() async {
    List<Player> currentPlayers =
        isTeamOneTurn ? [player1, player2] : [player3, player4];

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
                    _incrementPlayerAirballs(player);
                    Navigator.of(context).pop();
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
    });
  }

  // Function to check if the game has ended
  void _checkGameEnd() {
    bool teamOneAllHit = team1Cups.every((cup) => !cup.isVisible);
    bool teamTwoAllHit = team2Cups.every((cup) => !cup.isVisible);

    if (teamOneAllHit) {
      _showGameEndDialog([player1, player2]);
    } else if (teamTwoAllHit) {
      _showGameEndDialog([player3, player4]);
    }
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
                // Optionally, you can reset the game here.
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
              _newButtonAirball(),
            ]),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rows of cups for both teams, displayed conditionally based on whose turn it is
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isTeamOneTurn
                      ? team1Cups[6].widget(() => _showPlayerSelectionDialog(6))
                      : team2Cups[6]
                          .widget(() => _showPlayerSelectionDialog(6)),
                  isTeamOneTurn
                      ? team1Cups[7].widget(() => _showPlayerSelectionDialog(7))
                      : team2Cups[7]
                          .widget(() => _showPlayerSelectionDialog(7)),
                  isTeamOneTurn
                      ? team1Cups[8].widget(() => _showPlayerSelectionDialog(8))
                      : team2Cups[8]
                          .widget(() => _showPlayerSelectionDialog(8)),
                  isTeamOneTurn
                      ? team1Cups[9].widget(() => _showPlayerSelectionDialog(9))
                      : team2Cups[9]
                          .widget(() => _showPlayerSelectionDialog(9)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isTeamOneTurn
                      ? team1Cups[3].widget(() => _showPlayerSelectionDialog(3))
                      : team2Cups[3]
                          .widget(() => _showPlayerSelectionDialog(3)),
                  isTeamOneTurn
                      ? team1Cups[4].widget(() => _showPlayerSelectionDialog(4))
                      : team2Cups[4]
                          .widget(() => _showPlayerSelectionDialog(4)),
                  isTeamOneTurn
                      ? team1Cups[5].widget(() => _showPlayerSelectionDialog(5))
                      : team2Cups[5]
                          .widget(() => _showPlayerSelectionDialog(5)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isTeamOneTurn
                      ? team1Cups[1].widget(() => _showPlayerSelectionDialog(1))
                      : team2Cups[1]
                          .widget(() => _showPlayerSelectionDialog(1)),
                  isTeamOneTurn
                      ? team1Cups[2].widget(() => _showPlayerSelectionDialog(2))
                      : team2Cups[2]
                          .widget(() => _showPlayerSelectionDialog(2)),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  isTeamOneTurn
                      ? team1Cups[0].widget(() => _showPlayerSelectionDialog(0))
                      : team2Cups[0]
                          .widget(() => _showPlayerSelectionDialog(0)),
                ]),
              ],
            ),
            // Displaying the scores and misses of each player
            Text(
              '${player1.name} Score: ${player1.score} Misses: ${player1.misses}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${player2.name} Score: ${player2.score} Misses: ${player2.misses}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${player3.name} Score: ${player3.score} Misses: ${player3.misses}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${player4.name} Score: ${player4.score} Misses: ${player4.misses}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
              onPressed: () {},
              tooltip: 'Increment',
              child: const Icon(Icons.scatter_plot_outlined),
            ),
            FloatingActionButton.extended(
                heroTag: "miss",
                onPressed: _incrementPlayerMisses,
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
