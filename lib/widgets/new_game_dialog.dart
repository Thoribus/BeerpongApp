import 'package:flutter/material.dart';

class NewGameDialog extends StatefulWidget {
  final int team;
  final List<String> initialNames;

  const NewGameDialog({
    Key? key,
    required this.team,
    required this.initialNames,
  }) : super(key: key);

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  // Create a list of TextEditingController objects to manage player name inputs
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with initial names if provided
    if (widget.initialNames.isNotEmpty) {
      _controllers.addAll(
          widget.initialNames.map((name) => TextEditingController(text: name)));
    } else {
      // Initialize with default number of players (2 players)
      _controllers.addAll(List.generate(2, (_) => TextEditingController()));
    }
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
    return AlertDialog(
      title: Text('Edit Team ${widget.team}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              style: TextStyle(color: Colors.black),
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
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('SAVE'),
          onPressed: () {
            final List<String> names = _controllers
                .map((controller) => controller.text.trim())
                .toList();
            Navigator.of(context).pop(names);
          },
        ),
      ],
    );
  }
}
