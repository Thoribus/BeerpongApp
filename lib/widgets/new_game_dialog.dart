import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../util/firestoreservice.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../util/user_provider.dart';

/// Used as the return type when the dialog closes:
/// - [players] is the final list of Player objects (some might be user’s friends).
/// - [acceptedInvitations] is a list of invitation doc IDs that ended up accepted.
class NewGameDialogResult {
  final List<Player> players;
  final List<String> acceptedInvitations;

  NewGameDialogResult({
    required this.players,
    required this.acceptedInvitations,
  });
}

/// A dialog to configure a team with up to [numPlayers] players.
/// You can pick from your friend list or yourself, sending invitations as needed.
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
  /// One text controller per row (e.g., up to [numPlayers]).
  final List<TextEditingController> _controllers = [];

  /// Each row might correspond to a friend pick:
  ///   (rowIndex) -> selected [User].
  final Map<int, User> _friendMap = {};

  /// Track invitation doc IDs and statuses for real-time updates.
  ///   (rowIndex) -> docId
  final Map<int, String> _invitationDocIds = {};

  ///   (rowIndex) -> 'pending' | 'accepted' | 'declined'
  final Map<int, String> _invitationStatuses = {};

  /// Accumulate all accepted invitation IDs to return in the dialog result.
  final List<String> _acceptedInvitationIds = [];

  late int _numPlayers;

  @override
  void initState() {
    super.initState();
    _numPlayers = widget.numPlayers;

    // Pre-fill text fields with initial names or create empty ones
    if (widget.initialNames.isNotEmpty) {
      _controllers.addAll(
        widget.initialNames.map(
          (name) => TextEditingController(text: name),
        ),
      );
    } else {
      _controllers.addAll(
        List.generate(_numPlayers, (_) => TextEditingController()),
      );
    }
  }

  @override
  void dispose() {
    // Clean up text controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// If user taps SAVE, finalize the players and invitations.
  void _onSave() {
    // If any invitation is still 'pending', show a warning and do not close
    final anyPending = _invitationStatuses.values.contains('pending');
    if (anyPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one friend has not accepted yet!'),
        ),
      );
      return;
    }

    // Otherwise, build final players list
    final players = List<Player>.generate(_numPlayers, (i) {
      final name = _controllers[i].text.trim();
      final user = _friendMap[i]; // might be null if typed in manually
      return Player(name: name, user: user);
    });

    // Return a combined result: the players plus any accepted invitations
    final result = NewGameDialogResult(
      players: players,
      acceptedInvitations: _acceptedInvitationIds,
    );

    Navigator.of(context).pop(result);
  }

  /// Called when user taps the person icon to pick from friend list
  Future<void> _selectFromFriendList(int rowIndex) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in!')),
      );
      return;
    }

    // Fetch the user's friends
    final friends = await FirestoreService().getFriends(currentUser.id);
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No friends found!')),
      );
      return;
    }

    // Show a pick-dialog (AwesomeDialog) with yourself + friend grid
    await _showPickPlayerDialog(context, currentUser, friends).then(
      (selectedPlayer) async {
        if (selectedPlayer == null) return; // Canceled or closed

        // Fill in the text field with selected user’s name
        setState(() {
          _controllers[rowIndex].text = selectedPlayer.username;
          _friendMap[rowIndex] = selectedPlayer;
        });

        // If the user picks themselves, no invitation needed
        if (selectedPlayer.id == currentUser.id) {
          //return;
        }

        // Otherwise, create an invitation doc in Firestore
        final docId = await FirestoreService().sendGameInvitation(
          fromUserId: currentUser.id,
          toUserId: selectedPlayer.id,
          teamNumber: widget.team,
          playerIndex: rowIndex,
          // optionally pass a separate "gameId" if needed
        );

        // Mark this row as "pending" invitation
        setState(() {
          _invitationDocIds[rowIndex] = docId;
          _invitationStatuses[rowIndex] = 'pending';
        });

        // Start listening to this invitation doc for real-time status updates
        _listenToInvitationStatus(rowIndex, docId);

        // Notify user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invited ${selectedPlayer.username}')),
        );
      },
    );
  }

  /// Actually shows the pick player dialog (with your user + friends)
  /// and returns the chosen [User] or null.
  Future<User?> _showPickPlayerDialog(
    BuildContext context,
    User currentUser,
    List<User> friends,
  ) {
    // 1) Create a `Completer<User?>`.
    final completer = Completer<User?>();

    // 2) Build the body content for the AwesomeDialog
    final bodyWidget = _buildPickPlayerBody(
      context,
      currentUser,
      friends,
      completer,
    );

    // 3) Show the AwesomeDialog.
    //    NOTE: We do *not* return `.show()` directly, because that is `Future<dynamic>`
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dialogBackgroundColor: Colors.amber,
      width: 500,
      body: bodyWidget,
      // If there's a cancel button:
      btnCancelOnPress: () {
        // If user taps "Cancel," complete with null
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      btnCancelText: "Cancel",
    ).show();

    // 4) Return the `Future<User?>` from the completer.
    return completer.future;
  }

  /// This widget is used as the [body] of the AwesomeDialog above.
  /// Instead of calling `Navigator.pop(context, user)`, we do:
  ///   `completer.complete(user)` and `Navigator.pop(context)`.
  Widget _buildPickPlayerBody(
    BuildContext context,
    User currentUser,
    List<User> friends,
    Completer<User?> completer,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Choose a Player',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Option: pick yourself
          GestureDetector(
            onTap: () {
              if (!completer.isCompleted) {
                completer.complete(currentUser);
              }
              Navigator.pop(context); // close the dialog
            },
            child: Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    currentUser.username,
                    style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Quick example of showing up to 6 friends in a 2-col grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: (friends.length > 6) ? 6 : friends.length,
            itemBuilder: (ctx, i) {
              final friend = friends[i];
              return GestureDetector(
                onTap: () {
                  // user picks friend
                  if (!completer.isCompleted) {
                    completer.complete(friend);
                  }
                  Navigator.pop(context);
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
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // If more than 6 friends, a scrollable list for the rest
          if (friends.length > 6)
            SizedBox(
              height: 250,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: friends.length,
                itemBuilder: (ctx, i) {
                  final friend = friends[i];
                  return GestureDetector(
                    onTap: () {
                      if (!completer.isCompleted) {
                        completer.complete(friend);
                      }
                      Navigator.pop(context);
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
                                fontSize: 16.0, fontWeight: FontWeight.bold),
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
    );
  }

  /// Listen to the invitation doc. If status changes => update local UI.
  void _listenToInvitationStatus(int index, String docId) {
    FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        // Possibly the doc was deleted
        return;
      }
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';

      if (status == 'accepted' && data['gameId'] == null) {
        setState(() {
          // Mark invitation doc as accepted
          if (!_acceptedInvitationIds.contains(docId)) {
            _acceptedInvitationIds.add(docId);
          }
          _invitationStatuses[index] = status;
        });
      } else if (status == 'declined') {
        setState(() {
          // If declined, optionally remove the friend from the row
          FirestoreService().deleteGameInvitation(docId);
          _invitationDocIds.remove(index);
          _invitationStatuses.remove(index);
          _controllers[index].clear();
          _friendMap.remove(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      } else if (status == 'pending') {
        setState(() {
          _invitationStatuses[index] = status;
        });
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Team ${widget.team}'),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(_numPlayers, (i) {
            if (i >= _controllers.length) {
              _controllers.add(TextEditingController());
            }
            return _buildPlayerRow(i);
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(), // Cancels the entire dialog
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: _onSave, // Attempt to finalize
          child: const Text("SAVE"),
        ),
      ],
    );
  }

  /// Builds each row (TextField + icon + optional status text).
  Widget _buildPlayerRow(int i) {
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
            onPressed: () => _selectFromFriendList(i),
          ),
          if (_invitationStatuses.containsKey(i))
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                _buildStatusText(_invitationStatuses[i]!),
                style: const TextStyle(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }

  /// Helper: convert status into user-friendly text
  String _buildStatusText(String status) {
    if (status == 'pending') return 'pending...';
    if (status == 'accepted') return 'accepted!';
    if (status == 'declined') return 'declined';
    return status;
  }
}
