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
    _controllers.addAll(List.generate(_numPlayers, (_) => TextEditingController()));
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
        _controllers.addAll(List.generate(count - _controllers.length, (_) => TextEditingController()));
      } 
      // If the new count is less, remove excess controllers
      else if (count < _controllers.length) {
        _controllers.removeRange(count, _controllers.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Title of the dialog showing the team number
      title: Text('Enter Player Names for Team ${widget.team}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input field for the number of players
          TextField(
            decoration: const InputDecoration(labelText: 'Number of Players'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // Update the player fields based on the entered number
              int? count = int.tryParse(value);
              if (count != null && count > 0) {
                _updatePlayerFields(count);
              }
            },
          ),
          // Generate input fields for player names dynamically based on the number of controllers
          ..._controllers.map((controller) {
            int index = _controllers.indexOf(controller) + 1;
            return TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Player $index'),
            );
          }),
        ],
      ),
      actions: [
        // Cancel button to close the dialog without saving any input
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        // Button to save the input and pass it back to the previous screen
        ElevatedButton(
          onPressed: () {
            // Pass the entered player names back to the previous screen
            Navigator.of(context).pop(_controllers.map((controller) => controller.text).toList());
          },
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
