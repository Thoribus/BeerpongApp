import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// invitationDocIds: a map from each player index to the invitation doc ID.
  /// invitationStatuses: a map from each player index to the invitation status (pending/accepted/declined).
  final Map<int, String> _invitationDocIds = {};
  final Map<int, String> _invitationStatuses = {};

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

    // Check if currentUser is not null
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in!')),
      );
      return;
    }

    User? user = await FirestoreService().getUser(currentUser.uid);

    // Check if user data is retrieved successfully
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user data!')),
      );
      return;
    }

    _friends = await FirestoreService().getFriends(user.id);

    // Check if friends list is available
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No friends found!')),
      );
      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dialogBackgroundColor: Colors.amber,
      width: 500, // Fixed width for the dialog
      buttonsBorderRadius:
          BorderRadius.circular(12), // Rounded corners for buttons
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Choose a Player',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Current user option
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, user);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle,
                          size: 36.0, color: Colors.amber),
                      const SizedBox(width: 16.0),
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Friends list displayed in 2 columns and scrollable vertically if there are more than 6 friends
              GridView.builder(
                shrinkWrap:
                    true, // Prevents GridView from taking up too much space
                physics:
                    const NeverScrollableScrollPhysics(), // Prevents nested scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns
                  childAspectRatio: 1.0, // Aspect ratio of each item
                  crossAxisSpacing: 8.0, // Space between columns
                  mainAxisSpacing: 8.0, // Space between rows
                ),
                itemCount: _friends.length > 6
                    ? 6
                    : _friends
                        .length, // Limit the first 6 items, if there are more than 6 friends
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context, friend);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_circle,
                              size: 36.0, color: Colors.blue),
                          const SizedBox(height: 8.0),
                          Text(
                            friend.username,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // If there are more than 6 friends, make the list scrollable vertically
              if (_friends.length > 6)
                Container(
                  height:
                      250, // Adjust this height based on how much space you want for scrolling
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context, friend);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_circle,
                                  size: 36.0, color: Colors.blue),
                              const SizedBox(height: 8.0),
                              Text(
                                friend.username,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {},
      btnCancelText: "Cancel",
    ).show().then((selectedPlayer) async {
      if (selectedPlayer != null) {
        setState(() {
          _controllers[index].text = selectedPlayer.username;
          _friendMap[index] = selectedPlayer;
        });
        // Send an invitation to Firestore
        final currentUser = await FirestoreService().getUser(user.id);
        if (currentUser == null) return;

        // Don't send an invitation to yourself
        if (currentUser.id == selectedPlayer.id) return;

        final String docId = await FirestoreService().sendGameInvitation(
          fromUserId: currentUser.id,
          toUserId: selectedPlayer.id,
          teamNumber: widget.team,
          playerIndex: index,
        );

        setState(() {
          _invitationDocIds[index] = docId;
          _invitationStatuses[index] = 'pending'; // Start as "pending"
        });

        // 3) Listen for updates to that doc’s status
        _listenToInvitationStatus(index, docId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Selected player: ${selectedPlayer.username}')),
        );
      }
    });
  }

  void _listenToInvitationStatus(int index, String docId) {
    FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';

      // Once the doc changes to "accepted" or "declined", update local UI
      setState(() {
        _invitationStatuses[index] = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Team ${widget.team}'),
      content: SingleChildScrollView(
        child: Column(
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
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => selectFromFriendList(index),
                  ),
                  if (_invitationStatuses.containsKey(index))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _invitationStatuses[index] == 'pending'
                            ? 'pending...'
                            : _invitationStatuses[index] == 'accepted'
                                ? 'accepted!'
                                : 'declined',
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: () {
            final anyPending = _invitationStatuses.values.contains('pending');
            if (anyPending) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('At least one friend has not accepted yet!')),
              );
              return;
            }
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
          child: const Text("SAVE"),
        ),
      ],
    );
  }
}
