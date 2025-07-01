import 'dart:async';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../util/firestoreservice.dart';
import '../util/user_provider.dart';
import '../models/user.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/cup.dart';
import 'game/game_screen.dart';

class GameModeDetailsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String details;
  final String iconPath;
  final Color color;

  const GameModeDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.iconPath,
    required this.color,
  });

  @override
  State<GameModeDetailsScreen> createState() => _GameModeDetailsScreenState();
}

class _GameModeDetailsScreenState extends State<GameModeDetailsScreen> {
  // For the info pageview
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final PageController _bottomPageController = PageController();
  int _bottomCurrentPage = 0;
  final Set<int> _selectedTiles = {};

  final List<String> infoPages = [
    'Fast-paced fun for everyone!',
    'Pick the rules you want to use!',
    'Invite your friends for a challenge!',
  ];

  final List<_InfoTileData> tiles = [
    _InfoTileData(BeerpongIcons.airball, 'Airballs'),
    _InfoTileData(Icons.roundabout_left, 'Bounce'),
    _InfoTileData(Icons.sports_basketball_outlined, 'Putback'),
    _InfoTileData(BeerpongIcons.palm_tree, 'Island'),
    _InfoTileData(BeerpongIcons.skull, 'Deathcup'),
    _InfoTileData(BeerpongIcons.umstellen, 'Rearrange'),
  ];

  // --------- LOBBY LOGIC ---------
  String? _gameId;
  final List<Player> _playersBlue = [];
  final List<Player> _playersRed = [];
  final Map<int, String> _blueInvitationDocIds = {};
  final Map<int, String> _blueInvitationStatuses = {};
  final Map<int, User> _blueFriendMap = {};
  final Map<int, String> _redInvitationDocIds = {};
  final Map<int, String> _redInvitationStatuses = {};
  final Map<int, User> _redFriendMap = {};
  final List<String> _acceptedInvites = [];
  late final Map<String, bool> _selectedRules = {
    for (var tile in tiles) tile.text: false,
  };
  String _startingTeam = 'Team Blue';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _createGameDoc();
  }

  @override
  void dispose() {
    for (final docId in _blueInvitationDocIds.values) {
      if (docId.isNotEmpty) FirestoreService().deleteGameInvitation(docId);
    }
    for (final docId in _redInvitationDocIds.values) {
      if (docId.isNotEmpty) FirestoreService().deleteGameInvitation(docId);
    }
    if (!_started && _gameId != null) {
      FirestoreService().deleteGameDoc(_gameId!);
    }
    super.dispose();
  }

  Future<void> _createGameDoc() async {
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
    final docId = await FirestoreService().createEmptyGameDoc(
      team1: emptyTeamBlue,
      team2: emptyTeamRed,
    );
    setState(() {
      _gameId = docId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: infoPages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) => Column(
                      children: [
                        SvgPicture.asset(
                          widget.iconPath,
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          infoPages[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    infoPages.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300, // Adjust as needed
                  child: PageView(
                    controller: _bottomPageController,
                    onPageChanged: (index) =>
                        setState(() => _bottomCurrentPage = index),
                    children: [
                      // Page 1: Rule tiles (SCROLLABLE)
                      SingleChildScrollView(
                        child: Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              tiles.length,
                              (index) => _buildSelectableTile(index),
                            ),
                          ),
                        ),
                      ),
                      // Page 2: FULL LOBBY (SCROLLABLE)
                      SingleChildScrollView(
                        child: _buildLobbySection(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _bottomCurrentPage == index
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _canStartGame() ? _onStartGame : null,
                    child: const Text(
                      'Start Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbySection() {
    return Column(
      children: [
        const Text(
          'Lobby',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildTeamPanel(isBlue: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTeamPanel(isBlue: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamPanel({required bool isBlue}) {
    final teamName = isBlue ? "TEAM BLUE" : "TEAM RED";
    final color = isBlue ? Colors.blue : Colors.red;
    final players = isBlue ? _playersBlue : _playersRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontSize: 16,
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
                  players.add(Player(name: "", user: null));
                });
                _updateGameDoc();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Player",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerRow({required bool isBlue, required int rowIndex}) {
    final players = isBlue ? _playersBlue : _playersRed;
    final invitationStatuses =
        isBlue ? _blueInvitationStatuses : _redInvitationStatuses;
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
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        _updateGameDoc();
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

  // -------------- INVITATION LOGIC ------------------
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
    if (selected.id == currentUser.id) {
      setState(() {
        players[rowIndex] = players[rowIndex].copyWithName(selected.username);
        players[rowIndex] = players[rowIndex].copyWithUser(selected);
      });
      _updateGameDoc();
      return;
    }
    setState(() {
      players[rowIndex] = players[rowIndex].copyWithName(selected.username);
      players[rowIndex] = players[rowIndex].copyWithUser(selected);
    });
    final docId = await FirestoreService().sendGameInvitation(
      fromUserId: currentUser.id,
      toUserId: selected.id,
      teamNumber: isBlue ? 1 : 2,
      playerIndex: rowIndex,
      gameId: _gameId!,
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
    _updateGameDoc();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invited ${selected.username}')),
    );
  }

  Future<User?> _showPickPlayerDialog(
      User currentUser, List<User> friends) async {
    final completer = Completer<User?>();
    final bodyWidget = _buildPickPlayerBody(currentUser, friends, completer);
    await showDialog<User?>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[850],
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(12),
            child: bodyWidget,
          ),
        );
      },
    );
    return completer.future;
  }

  Widget _buildPickPlayerBody(
      User currentUser, List<User> friends, Completer<User?> completer) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Select a Player',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          Divider(color: Colors.grey.shade300),
          GestureDetector(
            onTap: () {
              if (!completer.isCompleted) completer.complete(currentUser);
              Navigator.pop(context);
            },
            child: _buildPlayerOptionCard(
                currentUser, "You", Icons.account_circle, Colors.amber),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            itemBuilder: (ctx, index) {
              final friend = friends[index];
              return GestureDetector(
                onTap: () {
                  if (!completer.isCompleted) completer.complete(friend);
                  Navigator.pop(context);
                },
                child: _buildPlayerOptionCard(
                    friend, "Friend", Icons.person, Colors.blue),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerOptionCard(
      User player, String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: ClipOval(
              child: SvgPicture.asset(
                player.mapAvatarKeyToAsset(),
                fit: BoxFit.cover,
                width: 36,
                height: 36,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username,
                  style: const TextStyle(
                      fontSize: 14.0, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            size: 24.0,
            color: color,
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
          if (isBlue) {
            final friend = _blueFriendMap[rowIndex];
            if (friend != null) {
              _playersBlue[rowIndex] =
                  _playersBlue[rowIndex].copyWithName(friend.username);
              _playersBlue[rowIndex] =
                  _playersBlue[rowIndex].copyWithUser(friend);
            }
            _blueInvitationStatuses.remove(rowIndex);
          } else {
            final friend = _redFriendMap[rowIndex];
            if (friend != null) {
              _playersRed[rowIndex] =
                  _playersRed[rowIndex].copyWithName(friend.username);
              _playersRed[rowIndex] =
                  _playersRed[rowIndex].copyWithUser(friend);
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
    final docId = isBlue
        ? _blueInvitationDocIds[rowIndex]
        : _redInvitationDocIds[rowIndex];
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

  // ---------- GAME SETTINGS AND START -----------
  Future<void> _updateGameDoc() async {
    if (_gameId == null) return;
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
    await FirestoreService().updateGameDoc(
      _gameId!,
      team1: teamBlue,
      team2: teamRed,
      rules: _selectedRules.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      startingTeam: _startingTeam,
      invitations: _acceptedInvites,
      started: _started,
      timestamp: true,
    );
  }

  bool _canStartGame() {
    if (_playersBlue.isEmpty || _playersRed.isEmpty) return false;
    if (_playersBlue.any((p) => p.name.trim().isEmpty)) return false;
    if (_playersRed.any((p) => p.name.trim().isEmpty)) return false;
    if (_blueInvitationStatuses.values.contains('pending')) return false;
    if (_redInvitationStatuses.values.contains('pending')) return false;
    return true;
  }

  Future<void> _onStartGame() async {
    if (_gameId == null) return;
    // Show the starting team dialog BEFORE proceeding
    String? chosenTeam = await _showStartingTeamDialog();

    if (chosenTeam == null) {
      // Dialog was dismissed/canceled
      return;
    }
    for (final inviteId in _acceptedInvites) {
      await FirestoreService().updateInvitationGameId(inviteId, _gameId!);
    }
    setState(() {
      _started = true;
      _startingTeam = chosenTeam;
    });
    _updateGameDoc();
    Navigator.pushReplacement(
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

  Future<String?> _showStartingTeamDialog() async {
    // Adjust team names if you want dynamic team names
    const team1Name = "Team Blue";
    const team2Name = "Team Red";
    final team1Players =
        _playersBlue.map((p) => p.name).where((n) => n.isNotEmpty).toList();
    final team2Players =
        _playersRed.map((p) => p.name).where((n) => n.isNotEmpty).toList();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Who starts?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(team1Name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        ...team1Players.map((n) => Text(n)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('VS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(team2Name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        ...team2Players.map((n) => Text(n)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Which team should start?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(team1Name),
              child: const Text('$team1Name starts',
                  style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(team2Name),
              child: const Text('$team2Name starts',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectableTile(int index) {
    final isSelected = _selectedTiles.contains(index);
    final tile = tiles[index];
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedTiles.remove(index);
        } else {
          _selectedTiles.add(index);
        }
        // Optionally: update your rules logic here
        _selectedRules[tile.text] = !isSelected;
        print(_selectedRules);
      }),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tile.icon,
              color: isSelected ? Colors.amber[800] : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              tile.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.amber[800] : Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTileData {
  final IconData icon;
  final String text;
  _InfoTileData(this.icon, this.text);
}

// --------------------
// Player extension
// --------------------
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
