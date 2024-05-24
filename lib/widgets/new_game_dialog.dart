import 'package:flutter/material.dart'; // Importing necessary Flutter package

// NewGameDialog is a stateful widget that displays a dialog for entering player names for a specified team.
class NewGameDialog extends StatefulWidget {
  const NewGameDialog({super.key, required this.team});

  final int team; // The team number for which player names are being entered

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

// The state for the NewGameDialog widget.
class _NewGameDialogState extends State<NewGameDialog> {
  final TextEditingController _player1Controller = TextEditingController(); // Controller for player 1 name input
  final TextEditingController _player2Controller = TextEditingController(); // Controller for player 2 name input

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Player Names for Team ${widget.team}'), // Title of the dialog
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _player1Controller,
            decoration: const InputDecoration(labelText: 'Player 1'), // Input field for player 1 name
          ),
          TextField(
            controller: _player2Controller,
            decoration: const InputDecoration(labelText: 'Player 2'), // Input field for player 2 name
          ),
        ],
      ),
      actions: [
        // Cancel button to close the dialog without saving
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        // Start Game button to save the entered names and close the dialog
        ElevatedButton(
          onPressed: () {
            // Pass the entered names back to the previous screen
            Navigator.of(context).pop([
              _player1Controller.text,
              _player2Controller.text,
            ]);
          },
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
