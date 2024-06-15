import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/game_screen.dart';
import 'package:beerpongapp/widgets/new_game_dialog.dart';
import '../models/player.dart';

class SelectionScreen extends StatefulWidget {
  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  List<Player> players1 = [];
  List<Player> players2 = [];
  String selectedGameMode = 'Single Game';
  List<String> gameModes = ['Single Game', 'Tournament'];
  List<String> specialRules = ['Rule 1', 'Rule 2', 'Rule 3'];
  List<String> selectedRules = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Players',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            (players1.isEmpty && players2.isEmpty)
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () async {
                      // Show dialog for team 1 and cast the result to List<String>
                      final team1Result = await showDialog<List<String>>(
                        context: context,
                        builder: (context) => const NewGameDialog(team: 1),
                      );

                      if (team1Result != null) {
                        setState(() {
                          players1 = team1Result
                              .map((name) => Player(name: name))
                              .toList();
                        });

                        // Show dialog for team 2 and cast the result to List<String>
                        final team2Result = await showDialog<List<String>>(
                          context: context,
                          builder: (context) => const NewGameDialog(team: 2),
                        );
                        if (team2Result != null) {
                          setState(() {
                            players2 = team2Result
                                .map((name) => Player(name: name))
                                .toList();
                          });
                        }
                      }
                    },
                    child: const Text('Neues Spiel'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Team Blue:'),
                          ...players1.map((player) => Text(player.name)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Team Red:'),
                          ...players2.map((player) => Text(player.name)),
                        ],
                      )
                    ],
                  ),
            const SizedBox(height: 20),
            const Text('Select Game Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedGameMode,
              onChanged: (String? newValue) {
                setState(() {
                  selectedGameMode = newValue!;
                });
              },
              items: gameModes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Select Special Rules',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: specialRules.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(specialRules[index]),
                    value: selectedRules.contains(specialRules[index]),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedRules.add(specialRules[index]);
                        } else {
                          selectedRules.remove(specialRules[index]);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle the start of the game with selected options
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(
                        title: 'Beer Pong',
                        players1: players1,
                        players2: players2,
                      ),
                    ),
                  );
                },
                child: const Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
