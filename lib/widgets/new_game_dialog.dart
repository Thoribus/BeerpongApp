import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../util/firestoreservice.dart';
import '../models/user.dart';
import '../models/player.dart';

class NewGameDialog extends StatefulWidget {
  final int team;
  final List<String> initialNames;
  final int numPlayers;

  const NewGameDialog({
    super.key,
    required this.team,
    required this.initialNames,
    required this.numPlayers,
  });

  @override
  NewGameDialogState createState() => NewGameDialogState();
}

class NewGameDialogState extends State<NewGameDialog> {
  final List<TextEditingController> _controllers = [];
  late List<User> _friends;
  late int _numPlayers;
  final Map<int, User> _friendMap = {};

  @override
  void initState() {
    super.initState();

    _numPlayers = widget.numPlayers;

    if (widget.initialNames.isNotEmpty) {
      _controllers.addAll(
          widget.initialNames.map((name) => TextEditingController(text: name)));
    } else {
      _controllers
          .addAll(List.generate(_numPlayers, (_) => TextEditingController()));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> selectFromFriendList(int index) async {
    auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    User? user = await FirestoreService().getUser(currentUser!.uid);
    _friends = await FirestoreService().getFriends(user!.id);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose a player'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text(user.username),
                  onTap: () {
                    Navigator.of(context).pop(user);
                  },
                ),
                ..._friends.map((friend) => ListTile(
                      title: Text(friend.username),
                      onTap: () {
                        Navigator.of(context).pop(friend);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    ).then((selectedPlayer) {
      if (selectedPlayer != null) {
        setState(() {
          _controllers[index].text = selectedPlayer.username;
          _friendMap[index] = selectedPlayer;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected player: $selectedPlayer')),
        );
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
          children: List.generate(_numPlayers, (index) {
            if (index >= _controllers.length) {
              _controllers.add(TextEditingController());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.2),
                        labelText: 'Player ${index + 1}',
                        labelStyle: const TextStyle(color: Colors.amber),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                            width: 2.0,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => selectFromFriendList(index),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('SAVE'),
          onPressed: () {
            final List<Player> names =
                _controllers.take(_numPlayers).map((controller) {
              int index = _controllers.indexOf(controller);
              return Player(
                name: controller.text.trim(),
                user: _friendMap[index],
              );
            }).toList();
            Navigator.of(context).pop(names);
          },
        ),
      ],
    );
  }
}
