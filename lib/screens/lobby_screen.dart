import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:provider/provider.dart';
import '../util/firestoreservice.dart';
import '../util/user_provider.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/cup.dart';
import 'game/game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  // ----------------------------
  // Firebase game doc tracking
  // ----------------------------
  String? _gameId; // Will store the Firestore doc ID created in initState.

  // ----------------------------
  // Teams / players
  // ----------------------------
  final List<Player> _playersBlue = [];
  final List<Player> _playersRed = [];

  // For invitations
  final Map<int, String> _blueInvitationDocIds = {};
  final Map<int, String> _blueInvitationStatuses = {};
  final Map<int, User> _blueFriendMap = {};

  final Map<int, String> _redInvitationDocIds = {};
  final Map<int, String> _redInvitationStatuses = {};
  final Map<int, User> _redFriendMap = {};

  final List<String> _acceptedInvites = [];

  // ----------------------------
  // Game settings
  // ----------------------------
  String _selectedGameMode = 'Single Game';
  final List<String> _gameModes = ['Single Game', 'Tournament'];

  final Map<String, bool> _selectedRules = {
    'Deathcup': false,
    'Island': false,
    'Nachwurf': false,
  };

  String _startingTeam = 'Team Blue'; // Could be "Team Red" as well

  // ----------------------------
  // Lifecycle
  // ----------------------------
  @override
  void initState() {
    super.initState();
    _createGameDoc(); // Immediately create the Firestore doc
  }

  @override
  void dispose() {
    // Cancel all listeners
    for (final docId in _blueInvitationDocIds.values) {
      if (docId.isNotEmpty) {
        FirestoreService().deleteGameInvitation(docId);
      }
    }
    for (final docId in _redInvitationDocIds.values) {
      if (docId.isNotEmpty) {
        FirestoreService().deleteGameInvitation(docId);
      }
    }
    if (_gameId != null) FirestoreService().deleteGameDoc(_gameId!);
    super.dispose();
  }

  /// Creates a new empty "games" doc in Firestore as soon as LobbyScreen opens.
  Future<void> _createGameDoc() async {
    // Create minimal Team objects initially (empty players).
    final emptyTeamBlue = Team(
      color: Colors.blue,
      players: [],
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.blue)),
    );
    final emptyTeamRed = Team(
      color: Colors.red,
      players: [],
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.red)),
    );

    // FirestoreService call to create doc
    final docId = await FirestoreService().createEmptyGameDoc(
      team1: emptyTeamBlue,
      team2: emptyTeamRed,
      invitations: [], // No invites yet
    );

    setState(() {
      _gameId = docId;
    });

    debugPrint("LobbyScreen -> Created game doc: $docId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Lobby"),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Team Blue panel
            _buildTeamPanel(isBlue: true),
            const SizedBox(height: 16),
            // Team Red panel
            _buildTeamPanel(isBlue: false),
            const SizedBox(height: 16),
            // Game Settings
            _buildGameSettings(),
            const SizedBox(height: 16),
            // Start Game button
            ElevatedButton(
              onPressed: _canStartGame() ? _onStartGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canStartGame() ? Colors.amber : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Start Game",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // BUILD TEAM PANELS
  // ----------------------------
  Widget _buildTeamPanel({required bool isBlue}) {
    final teamName = isBlue ? "TEAM BLUE" : "TEAM RED";
    final color = isBlue ? Colors.blue : Colors.red;
    final players = isBlue ? _playersBlue : _playersRed;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(players.length, (index) {
              return _buildPlayerRow(isBlue: isBlue, rowIndex: index);
            }),
          ),
          if (players.length < 4) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  // Add an empty player
                  players.add(Player(name: "", user: null));
                });
                _updateGameDoc(); // update Firestore after adding
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Player", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerRow({required bool isBlue, required int rowIndex}) {
    final players = isBlue ? _playersBlue : _playersRed;
    final invitationStatuses = isBlue ? _blueInvitationStatuses : _redInvitationStatuses;
    final status = invitationStatuses[rowIndex];

    final player = players[rowIndex];
    final hasPickedFriendOrSelf = (player.user != null);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () {
          setState(() {
            _removePlayer(isBlue, rowIndex);
          });
          _updateGameDoc();
        },
      ),
      title: hasPickedFriendOrSelf
          ? _buildReadOnlyLabel(player)
          : _buildEditableField(players, rowIndex),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasPickedFriendOrSelf)
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => _onPickFriend(isBlue, rowIndex),
            ),
          if (status == 'pending') ...[
            const SizedBox(width: 8),
            const Text("pending...", style: TextStyle(color: Colors.amber)),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                _cancelInvitation(isBlue, rowIndex);
                _updateGameDoc();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyLabel(Player player) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        player.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditableField(List<Player> players, int rowIndex) {
    return TextFormField(
      initialValue: players[rowIndex].name,
      onChanged: (val) {
        setState(() {
          players[rowIndex] = players[rowIndex].copyWithName(val);
        });
        _updateGameDoc(); // update doc on every keystroke
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        fillColor: Colors.white10,
        filled: true,
        labelText: "Player ${rowIndex + 1}",
        labelStyle: const TextStyle(color: Colors.amber),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _removePlayer(bool isBlue, int rowIndex) {
    final players = isBlue ? _playersBlue : _playersRed;
    final docIds = isBlue ? _blueInvitationDocIds : _redInvitationDocIds;
    final statuses = isBlue ? _blueInvitationStatuses : _redInvitationStatuses;

    final docId = docIds[rowIndex];
    if (docId != null && docId.isNotEmpty) {
      FirestoreService().deleteGameInvitation(docId);
      docIds.remove(rowIndex);
      statuses.remove(rowIndex);
    }
    players.removeAt(rowIndex);
  }

  // ----------------------------
  // FRIEND INVITATION LOGIC
  // ----------------------------
  Future<void> _onPickFriend(bool isBlue, int rowIndex) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in!')),
      );
      return;
    }

    final friends = await FirestoreService().getFriends(currentUser.id);
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No friends found!')),
      );
      return;
    }

    final selected = await _showPickPlayerDialog(currentUser, friends);
    if (selected == null) return;

    final players = isBlue ? _playersBlue : _playersRed;

    // If user picks themselves => fill immediately, no invitation
    if (selected.id == currentUser.id) {
      setState(() {
        players[rowIndex] = players[rowIndex].copyWithName(selected.username);
        players[rowIndex] = players[rowIndex].copyWithUser(selected);
      });
      _updateGameDoc();
      return;
    }

    // Otherwise => friend. fill name + user, create invitation doc
    setState(() {
      players[rowIndex] = players[rowIndex].copyWithName(selected.username);
      players[rowIndex] = players[rowIndex].copyWithUser(selected);
    });

    final docId = await FirestoreService().sendGameInvitation(
      fromUserId: currentUser.id,
      toUserId: selected.id,
      teamNumber: isBlue ? 1 : 2,
      playerIndex: rowIndex,
    );

    if (isBlue) {
      _blueInvitationDocIds[rowIndex] = docId;
      _blueInvitationStatuses[rowIndex] = 'pending';
      _blueFriendMap[rowIndex] = selected;
    } else {
      _redInvitationDocIds[rowIndex] = docId;
      _redInvitationStatuses[rowIndex] = 'pending';
      _redFriendMap[rowIndex] = selected;
    }

    _listenToInvitationStatus(isBlue, rowIndex, docId);
    _updateGameDoc(); // update after picking friend

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invited ${selected.username}')),
    );
  }

  Future<User?> _showPickPlayerDialog(User currentUser, List<User> friends) async {
    final completer = Completer<User?>();
    final bodyWidget = _buildPickPlayerBody(currentUser, friends, completer);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dialogBackgroundColor: Colors.amber,
      width: 500,
      body: bodyWidget,
      btnCancelOnPress: () => completer.complete(null),
      btnCancelText: "Cancel",
    ).show();

    return completer.future;
  }

  Widget _buildPickPlayerBody(User currentUser, List<User> friends, Completer<User?> completer) {
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
              if (!completer.isCompleted) completer.complete(currentUser);
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, size: 36.0, color: Colors.amber),
                  const SizedBox(width: 16.0),
                  Text(
                    currentUser.username,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
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
                  if (!completer.isCompleted) completer.complete(friend);
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
                      const Icon(Icons.account_circle, size: 36.0, color: Colors.blue),
                      const SizedBox(height: 8.0),
                      Text(
                        friend.username,
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
                      if (!completer.isCompleted) completer.complete(friend);
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
                          const Icon(Icons.account_circle, size: 36.0, color: Colors.blue),
                          const SizedBox(height: 8.0),
                          Text(
                            friend.username,
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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

  void _listenToInvitationStatus(bool isBlue, int rowIndex, String docId) {
    FirebaseFirestore.instance
        .collection('invitations')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'pending';

      if (status == 'accepted') {
        setState(() {
          if (!_acceptedInvites.contains(docId)) {
            _acceptedInvites.add(docId);
          }
          // fill text field with friend if we stored it
          if (isBlue) {
            final friend = _blueFriendMap[rowIndex];
            if (friend != null) {
              _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithName(friend.username);
              _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithUser(friend);
            }
            _blueInvitationStatuses.remove(rowIndex);
          } else {
            final friend = _redFriendMap[rowIndex];
            if (friend != null) {
              _playersRed[rowIndex] = _playersRed[rowIndex].copyWithName(friend.username);
              _playersRed[rowIndex] = _playersRed[rowIndex].copyWithUser(friend);
            }
            _redInvitationStatuses.remove(rowIndex);
          }
        });
        _updateGameDoc();
      } else if (status == 'declined') {
        FirestoreService().deleteGameInvitation(docId);
        setState(() {
          if (isBlue) {
            _blueInvitationDocIds.remove(rowIndex);
            _blueInvitationStatuses.remove(rowIndex);
            _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithName("");
            _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithUser(null);
          } else {
            _redInvitationDocIds.remove(rowIndex);
            _redInvitationStatuses.remove(rowIndex);
            _playersRed[rowIndex] = _playersRed[rowIndex].copyWithName("");
            _playersRed[rowIndex] = _playersRed[rowIndex].copyWithUser(null);
          }
        });
        _updateGameDoc();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      } else if (status == 'pending') {
        setState(() {
          if (isBlue) {
            _blueInvitationStatuses[rowIndex] = 'pending';
          } else {
            _redInvitationStatuses[rowIndex] = 'pending';
          }
        });
        _updateGameDoc();
      }
    });
  }

  void _cancelInvitation(bool isBlue, int rowIndex) async {
    final docId = isBlue ? _blueInvitationDocIds[rowIndex] : _redInvitationDocIds[rowIndex];
    if (docId == null || docId.isEmpty) return;

    await FirestoreService().deleteGameInvitation(docId);

    setState(() {
      if (isBlue) {
        _blueInvitationDocIds.remove(rowIndex);
        _blueInvitationStatuses.remove(rowIndex);
        _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithName("");
        _playersBlue[rowIndex] = _playersBlue[rowIndex].copyWithUser(null);
      } else {
        _redInvitationDocIds.remove(rowIndex);
        _redInvitationStatuses.remove(rowIndex);
        _playersRed[rowIndex] = _playersRed[rowIndex].copyWithName("");
        _playersRed[rowIndex] = _playersRed[rowIndex].copyWithUser(null);
      }
    });
    _updateGameDoc();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation canceled')),
    );
  }

  // ----------------------------
  // GAME SETTINGS
  // ----------------------------
  Widget _buildGameSettings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Game Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 16),
            _buildGameModeToggle(),
            const SizedBox(height: 16),
            _buildSpecialRulesToggle(),
            const SizedBox(height: 16),
            _buildStartingTeamToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Game Mode", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: _gameModes.map((mode) {
            bool selected = (mode == _selectedGameMode);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGameMode = mode;
                });
                _updateGameDoc();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? Colors.amber : Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialRulesToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Special Rules", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: _selectedRules.keys.map((rule) {
            bool isActive = _selectedRules[rule] ?? false;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRules[rule] = !isActive;
                });
                _updateGameDoc();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber : Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rule,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartingTeamToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Starting Team", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: ["Team Blue", "Team Red"].map((team) {
            bool selected = (_startingTeam == team);
            final color = (team == "Team Blue") ? Colors.blue : Colors.red;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _startingTeam = team;
                });
                _updateGameDoc();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  team,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ----------------------------
  // UPDATING THE GAME DOC
  // ----------------------------
  Future<void> _updateGameDoc() async {
    // If the doc isn't created yet, do nothing
    if (_gameId == null) return;

    // Build the teams
    final teamBlue = Team(
      color: Colors.blue,
      players: _playersBlue,
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.blue)),
    );
    final teamRed = Team(
      color: Colors.red,
      players: _playersRed,
      cups: List.generate(10, (index) => Cup(index: index, color: Colors.red)),
    );

    // Optionally store the rules & gameMode in the doc too
    // (You could add them to updateData or store them in Team if you want)
    // Here we only store teams.

    await FirestoreService().updateGameDoc(
      _gameId!,
      team1: teamBlue,
      team2: teamRed,
      gameMode: _selectedGameMode,
      rules: _selectedRules.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
      // winner: null if not decided
    );

    debugPrint("Updated game doc $_gameId with current lobby changes.");
  }

  // ----------------------------
  // START GAME
  // ----------------------------
  bool _canStartGame() {
    // At least 1 player in each team
    if (_playersBlue.isEmpty || _playersRed.isEmpty) return false;
    // No empty names
    if (_playersBlue.any((p) => p.name.trim().isEmpty)) return false;
    if (_playersRed.any((p) => p.name.trim().isEmpty)) return false;
    // No invitation is still pending
    if (_blueInvitationStatuses.values.contains('pending')) return false;
    if (_redInvitationStatuses.values.contains('pending')) return false;
    return true;
  }

  Future<void> _onStartGame() async {
    if (_gameId == null) {
      // If something failed and we have no doc, do nothing or create
      return;
    }

    // Mark any acceptedInvites with gameId
    for (final inviteId in _acceptedInvites) {
      await FirestoreService().updateInvitationGameId(inviteId, _gameId!);
    }

    // Move to the actual game screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          id: _gameId!,
          players1: _playersBlue,
          players2: _playersRed,
          selectedRules: _selectedRules,
          invitations: _acceptedInvites,
          startingTeam: _startingTeam == "Team Blue",
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// EXTENSION: Player copyWithName / copyWithUser
// ----------------------------------------------------------------
extension PlayerExtensions on Player {
  Player copyWithName(String newName) {
    return Player(
      name: newName,
      user: user,
      score: score,
      throws: throws,
      misses: misses,
      airballs: airballs,
      defended: defended,
      consecutiveHits: consecutiveHits,
      cupsHit: cupsHit,
      hitThisRound: hitThisRound,
      onFire: onFire,
      islandShotUsed: islandShotUsed,
      lastCupHit: lastCupHit,
    );
  }

  Player copyWithUser(User? newUser) {
    return Player(
      name: name,
      user: newUser,
      score: score,
      throws: throws,
      misses: misses,
      airballs: airballs,
      defended: defended,
      consecutiveHits: consecutiveHits,
      cupsHit: cupsHit,
      hitThisRound: hitThisRound,
      onFire: onFire,
      islandShotUsed: islandShotUsed,
      lastCupHit: lastCupHit,
    );
  }
}
