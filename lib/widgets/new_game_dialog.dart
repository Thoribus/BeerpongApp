import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../util/firestoreservice.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../util/user_provider.dart';

/// Encapsulates both the chosen Players and any accepted Invitation IDs.
class NewGameDialogResult {
  final List<Player> players;
  final List<String> acceptedInvitations;

  NewGameDialogResult({
    required this.players,
    required this.acceptedInvitations,
  });
}

class NewGameDialog extends StatefulWidget {
  final int team;
  final List<String> initialNames;
  final int numPlayers;

  const NewGameDialog({
    Key? key,
    required this.team,
    required this.initialNames,
    required this.numPlayers,
  }) : super(key: key);

  @override
  NewGameDialogState createState() => NewGameDialogState();
}

class NewGameDialogState extends State<NewGameDialog> {
  final List<TextEditingController> _controllers = [];

  /// For each input row, we store a selected [User] if the user picked a friend or themselves.
  final Map<int, User> _friendMap = {};

  /// We track invitation doc IDs and statuses by player index, for real-time updates.
  final Map<int, String> _invitationDocIds = {};   // (playerIndex -> docId)
  final Map<int, String> _invitationStatuses = {}; // (playerIndex -> 'pending'/'accepted'/'declined')

  /// A list of invitation doc IDs that ended up being accepted.
  final List<String> _acceptedInvitationIds = [];

  late int _numPlayers;

  @override
  void initState() {
    super.initState();

    _numPlayers = widget.numPlayers;
    if (widget.initialNames.isNotEmpty) {
      // Pre-fill controllers from initialNames
      _controllers.addAll(widget.initialNames.map(
        (name) => TextEditingController(text: name),
      ));
    } else {
      // Create empty controllers for each player slot
      _controllers.addAll(
        List.generate(_numPlayers, (_) => TextEditingController()),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// If the user taps "SAVE"
  void _onSave() {
    // If any invitation is still 'pending', show a warning
    final anyPending = _invitationStatuses.values.contains('pending');
    if (anyPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one friend has not accepted yet!'),
        ),
      );
      return;
    }

    // Build the final list of [Player]
    final players = _controllers.take(_numPlayers).map((controller) {
      final index = _controllers.indexOf(controller);
      return Player(
        name: controller.text.trim(),
        user: _friendMap[index], // Might be null if not a friend
      );
    }).toList();

    // Return both the players and the accepted invites
    final result = NewGameDialogResult(
      players: players,
      acceptedInvitations: _acceptedInvitationIds,
    );

    Navigator.of(context).pop(result);
  }

  /// Called when the user taps the [person] icon to pick from friend list or themselves
  Future<void> selectFromFriendList(int index) async {
    // Instead of calling auth.FirebaseAuth directly, use the UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    // Check if currentUser is not null
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in!')),
      );
      return;
    }

    // Retrieve the user's friends
    final friends = await FirestoreService().getFriends(currentUser.id);
    if (friends.isEmpty) {
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
      width: 500, // or whatever width works for you
      buttonsBorderRadius: BorderRadius.circular(12),
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
              // Option for current user themselves
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, currentUser);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 36.0,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 16.0),
                      Text(
                        currentUser.username,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Show up to 6 friends in a 2-col grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: friends.length > 6 ? 6 : friends.length,
                itemBuilder: (ctx, i) {
                  final friend = friends[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, friend),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 36.0,
                            color: Colors.blue,
                          ),
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
              // If there are more than 6 friends, a scrollable grid
              if (friends.length > 6)
                Container(
                  height: 250,
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
                    itemCount: friends.length,
                    itemBuilder: (ctx, i) {
                      final friend = friends[i];
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, friend),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 36.0,
                                color: Colors.blue,
                              ),
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

        // If selectedPlayer is the current user, no invitation needed
        if (selectedPlayer.id == currentUser.id) {
          return;
        }

        // Otherwise, we create an invitation doc.
        final docId = await FirestoreService().sendGameInvitation(
          fromUserId: currentUser.id,
          toUserId: selectedPlayer.id,
          teamNumber: widget.team,
          playerIndex: index,
        );

        setState(() {
          _invitationDocIds[index] = docId;
          _invitationStatuses[index] = 'pending'; 
        });

        // Listen for status updates in Firestore
        _listenToInvitationStatus(index, docId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected player: ${selectedPlayer.username}'),
          ),
        );
      }
    });
  }

  /// Listens to Firestore doc changes for the invitation's status
  void _listenToInvitationStatus(int index, String docId) {
    FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return; // doc was deleted or never existed
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';

      // Update the UI based on status
      setState(() {
        _invitationStatuses[index] = status;
        if (status == 'accepted') {
          // Mark this docId as accepted
          if (!_acceptedInvitationIds.contains(docId)) {
            _acceptedInvitationIds.add(docId);
          }
        } else if (status == 'declined') {
          // If declined, you can optionally delete the doc and clear user from the row
          FirestoreService().deleteGameInvitation(docId);
          _invitationDocIds.remove(index);
          _invitationStatuses.remove(index);
          _controllers[index].clear();
          _friendMap.remove(index);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Team ${widget.team}'),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(_numPlayers, (i) {
            // Ensure we have a controller for each row
            if (i >= _controllers.length) {
              _controllers.add(TextEditingController());
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.2),
                        labelText: 'Player ${i + 1}',
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
                    onPressed: () => selectFromFriendList(i),
                  ),
                  if (_invitationStatuses.containsKey(i))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _invitationStatuses[i] == 'pending'
                            ? 'pending...'
                            : _invitationStatuses[i] == 'accepted'
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
          onPressed: () => Navigator.of(context).pop(), // user cancels entirely
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: _onSave, // finalize the dialog, returning the result
          child: const Text("SAVE"),
        ),
      ],
    );
  }
}
