import 'package:flutter/material.dart';

class SelectionScreen extends StatefulWidget {
  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  List<String> players = [];
  String selectedGameMode = 'Single Game';
  List<String> gameModes = ['Single Game', 'Tournament'];
  List<String> specialRules = ['Rule 1', 'Rule 2', 'Rule 3'];
  List<String> selectedRules = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: players.length + 1,
                itemBuilder: (context, index) {
                  if (index == players.length) {
                    return ListTile(
                      title: TextField(
                        decoration: InputDecoration(hintText: 'Add Player'),
                        onSubmitted: (value) {
                          setState(() {
                            players.add(value);
                          });
                        },
                      ),
                    );
                  }
                  return ListTile(
                    title: Text(players[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          players.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Select Game Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            Text('Select Special Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
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
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle the start of the game with selected options
                  Navigator.pop(context, {
                    'players': players,
                    'gameMode': selectedGameMode,
                    'specialRules': selectedRules,
                  });
                },
                child: Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
