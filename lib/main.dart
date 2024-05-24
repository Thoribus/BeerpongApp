import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.white,
          textTheme: ButtonTextTheme.primary,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Set HomeScreen as the initial route
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const NewGameDialog(team: 1)).then((result) {
                  if (result != null) {
                    // Start the game with the entered player names
                    String player1Name = result[0];
                    String player2Name = result[1];
                    showDialog(
                        context: context,
                        builder: (context) => const NewGameDialog(team: 2)).then((result) {
                      if (result != null) {
                        // Start the game with the entered player names
                        String player3Name = result[0];
                        String player4Name = result[1];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyHomePage(
                              title: 'Beer Pong',
                              players: [
                                Player(player1Name),
                                Player(player2Name),
                                Player(player3Name),
                                Player(player4Name),
                              ],
                            ),
                          ),
                        );
                      }
                    });
                    // Start the game with the entered player names
                  }
                });
              },
              child: Text('Neues Spiel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Statistik screen
              },
              child: const Text('Statistik'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Freundesliste screen
              },
              child: const Text('Freundesliste'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Einstellungen screen
              },
              child: const Text('Einstellungen'),
            ),
          ],
        ),
      ),
    );
  }
}

class Player {
  final String name;
  int score;
  int misses;
  int airballs;
  bool hitThisRound;

  Player(this.name)
      : score = 0,
        misses = 0,
        airballs = 0,
        hitThisRound = false;

  void incrementScore() {
    score++;
    hitThisRound = true;
  }

  void incrementMisses() {
    misses++;
  }

  void resetHitThisRound() {
    hitThisRound = false;
  }

  void incrementAirballs() {
    airballs++;
  }
}

class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key, required this.team});

  final int team;

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Player Names for Team ${widget.team}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _player1Controller,
            decoration: InputDecoration(labelText: 'Player 1'),
          ),
          TextField(
            controller: _player2Controller,
            decoration: InputDecoration(labelText: 'Player 2'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Pass the entered names back to the previous screen
            Navigator.of(context).pop([
              _player1Controller.text,
              _player2Controller.text,
            ]);
          },
          child: Text('Start Game'),
        ),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.players});

  final String title;
  final List<Player> players;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Player player1 = Player(widget.players[0].name);
  late Player player2 = Player(widget.players[1].name);
  late Player player3 = Player(widget.players[2].name);
  late Player player4 = Player(widget.players[3].name);

  List<Cup> team1Cups = List.generate(10, (index) => Cup(index));
  List<Cup> team2Cups = List.generate(10, (index) => Cup(index));

  bool isTeamOneTurn = true;

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

  Future<void> _confirmEndTurn() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm End Turn'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
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
              // Call the method to end the turn here
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
      _checkGameEnd();
    });
  }

  void _incrementPlayerMisses() {
    setState(() {
      List<Player> currentPlayers =
          isTeamOneTurn ? [player1, player2] : [player3, player4];
      for (var player in currentPlayers) {
        player.incrementMisses();
      }
    });
  }

  void _hideCup(int index) {
    setState(() {
      if (isTeamOneTurn) {
        team1Cups[index].isVisible = false;
      } else {
        team2Cups[index].isVisible = false;
      }
    });
  }

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

  _newButtonAirball() {
    return Visibility(
        child: FloatingActionButton.extended(
            heroTag: "airball",
            onPressed: _showAirballPlayerSelectionDialog,
            tooltip: 'Airball',
            label: const Text('Airball'),
            icon: const Icon(Icons.air_rounded)));
  }

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

  void _incrementPlayerAirballs(Player player) {
    setState(() {
      player.incrementAirballs();
      print("Airball for ${player.name} total: ${player.airballs}");
    });
  }

  void _checkGameEnd() {
    bool teamOneAllHit = team1Cups.every((cup) => !cup.isVisible);
    bool teamTwoAllHit = team2Cups.every((cup) => !cup.isVisible);

    if (teamOneAllHit) {
      _showGameEndDialog([player1, player2]);
    } else if (teamTwoAllHit) {
      _showGameEndDialog([player3, player4]);
    }
  }

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

class Cup {
  final int index;
  bool isVisible;

  Cup(this.index) : isVisible = true;

  Widget widget(VoidCallback onTap) {
    return Visibility(
      visible: isVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(10.0),
          width: 50.0,
          height: 50.0,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
