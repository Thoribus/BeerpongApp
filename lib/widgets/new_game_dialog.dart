import 'package:flutter/material.dart';

// Define a stateful widget for the new game dialog
class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key, required this.team});

  // Define a final integer field for the team number
  final int team;

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  // Define a variable to keep track of the number of players
  final int _numPlayers = 2;

  // Create a list of TextEditingController objects to manage player name inputs
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize the controllers for the default number of players (2 players)
    _controllers
        .addAll(List.generate(_numPlayers, (_) => TextEditingController()));
  }

  @override
  void dispose() {
    // Dispose of all controllers when the widget is disposed to free up resources
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Method to update the number of player input fields based on the count
  void _updatePlayerFields(int count) {
    setState(() {
      // If the new count is greater, add more controllers
      if (count > _controllers.length) {
        _controllers.addAll(List.generate(
            count - _controllers.length, (_) => TextEditingController()));
      }
      // If the new count is less, remove excess controllers
      else if (count < _controllers.length) {
        _controllers.removeRange(count, _controllers.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background color to black
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: widget.team == 1 ? Colors.red : Colors.blue,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Team ${widget.team}',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.amber.withOpacity(0.2),
                    labelText: 'Number of Players',
                    labelStyle: TextStyle(color: Colors.amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Colors.amber,
                        width: 2.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Colors.amber,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Colors.amber,
                        width: 2.0,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // Update the player fields based on the entered number
                    int? count = int.tryParse(value);
                    if (count != null && count > 0) {
                      _updatePlayerFields(count);
                    }
                  },
                ),
                const SizedBox(height: 16.0),
                ..._controllers.map((controller) {
                  int index = _controllers.indexOf(controller) + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.2),
                        labelText: 'Player $index',
                        labelStyle: TextStyle(color: Colors.amber),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: () {
                        // Pass the entered player names back to the previous screen
                        Navigator.of(context).pop(_controllers
                            .map((controller) => controller.text)
                            .toList());
                      },
                      child: const Text('Start Game'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
