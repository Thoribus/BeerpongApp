import 'dart:async';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/screens/tournament/tournament_page_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../util/firestoreservice.dart';
import '../../util/user_provider.dart';
import '../../models/user.dart';
import '../../models/player.dart';
import '../../models/team.dart';
import '../../models/cup.dart';
import '../../models/tournament.dart'; // <<- IMPORTANT!
import 'tournament_overview_screen.dart'; // <-- You'll have to make this, or point to your actual bracket/overview

class TournamentLobbyScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String details;
  final String iconPath;
  final Color color;

  const TournamentLobbyScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.iconPath,
    required this.color,
  });

  @override
  State<TournamentLobbyScreen> createState() => _TournamentLobbyScreenState();
}

class _TournamentLobbyScreenState extends State<TournamentLobbyScreen> {
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

  final List<Player> _players = [];
  final Map<int, String> _invitationDocIds = {};
  final Map<int, String> _invitationStatuses = {};
  final Map<int, User> _friendMap = {};
  final List<String> _acceptedInvites = [];
  late final Map<String, bool> _selectedRules = {
    for (var tile in tiles) tile.text: false,
  };

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
                  height: 300,
                  child: PageView(
                    controller: _bottomPageController,
                    onPageChanged: (index) =>
                        setState(() => _bottomCurrentPage = index),
                    children: [
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
                    onPressed:
                        _canStartTournament() ? _onStartTournament : null,
                    child: const Text(
                      'Start Tournament',
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
            Expanded(child: _buildPlayerPanel()),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerPanel() {
    final players = _players;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            "Players",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(players.length, (index) {
              return _buildPlayerRow(rowIndex: index);
            }),
          ),
          if (players.length < 8) ...[
            // Allow more in a tournament
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  players.add(Player(name: "", user: null));
                });
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

  Widget _buildPlayerRow({required int rowIndex}) {
    final players = _players;
    final invitationStatuses = _invitationStatuses;
    final status = invitationStatuses[rowIndex];
    final player = players[rowIndex];
    final hasPickedFriendOrSelf = (player.user != null);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () {
          setState(() {
            _removePlayer(rowIndex);
          });
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
              onPressed: () => _onPickFriend(rowIndex),
            ),
          if (status == 'pending') ...[
            const SizedBox(width: 8),
            const Text("pending...", style: TextStyle(color: Colors.amber)),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                _cancelInvitation(rowIndex);
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

  void _removePlayer(int rowIndex) {
    final players = _players;
    final docIds = _invitationDocIds;
    final statuses = _invitationStatuses;
    final docId = docIds[rowIndex];
    if (docId != null && docId.isNotEmpty) {
      FirestoreService().deleteGameInvitation(docId);
      docIds.remove(rowIndex);
      statuses.remove(rowIndex);
    }
    players.removeAt(rowIndex);
  }

  Future<void> _onPickFriend(int rowIndex) async {
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
    final players = _players;
    if (selected.id == currentUser.id) {
      setState(() {
        players[rowIndex] = players[rowIndex].copyWithName(selected.username);
        players[rowIndex] = players[rowIndex].copyWithUser(selected);
      });
      return;
    }
    setState(() {
      players[rowIndex] = players[rowIndex].copyWithName(selected.username);
      players[rowIndex] = players[rowIndex].copyWithUser(selected);
    });
    final docId = await FirestoreService().sendGameInvitation(
      fromUserId: currentUser.id,
      toUserId: selected.id,
      teamNumber: 1,
      playerIndex: rowIndex,
      gameId:
          '', // Not needed for tournament, but kept for FirestoreService compatibility
    );
    _invitationDocIds[rowIndex] = docId;
    _invitationStatuses[rowIndex] = 'pending';
    _friendMap[rowIndex] = selected;
    _listenToInvitationStatus(rowIndex, docId);
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

  void _listenToInvitationStatus(int rowIndex, String docId) {
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
          final friend = _friendMap[rowIndex];
          if (friend != null) {
            _players[rowIndex] =
                _players[rowIndex].copyWithName(friend.username);
            _players[rowIndex] = _players[rowIndex].copyWithUser(friend);
          }
          _invitationStatuses.remove(rowIndex);
        });
      } else if (status == 'declined') {
        FirestoreService().deleteGameInvitation(docId);
        setState(() {
          _invitationDocIds.remove(rowIndex);
          _invitationStatuses.remove(rowIndex);
          _players[rowIndex] = _players[rowIndex].copyWithName("");
          _players[rowIndex] = _players[rowIndex].copyWithUser(null);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      } else if (status == 'pending') {
        setState(() {
          _invitationStatuses[rowIndex] = 'pending';
        });
      }
    });
  }

  void _cancelInvitation(int rowIndex) async {
    final docId = _invitationDocIds[rowIndex];
    if (docId == null || docId.isEmpty) return;
    await FirestoreService().deleteGameInvitation(docId);
    setState(() {
      _invitationDocIds.remove(rowIndex);
      _invitationStatuses.remove(rowIndex);
      _players[rowIndex] = _players[rowIndex].copyWithName("");
      _players[rowIndex] = _players[rowIndex].copyWithUser(null);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation canceled')),
    );
  }

  bool _canStartTournament() {
    if (_players.length <= 1) return false;
    if (_players.any((p) => p.name.trim().isEmpty)) return false;
    if (_invitationStatuses.values.contains('pending')) return false;
    return true;
  }

  Future<void> _onStartTournament() async {
    // 1. Each player is a team of one.
    final List<Color> teamColors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
      // ...add more if needed!
    ];

    List<Team> teams = _players.asMap().entries.map((entry) {
      final i = entry.key;
      final player = entry.value;
      final color = teamColors[i % teamColors.length];
      return Team(
        color: color,
        players: [player],
        cups: List.generate(10, (index) => Cup(index: index, color: color)),
      );
    }).toList();

    // 2. Generate matches (round robin)
    List<TournamentMatch> matches =
        generateRoundRobinMatches(teams, _selectedRules, _acceptedInvites);

    // 3. Build Tournament object
    String tournamentId =
        FirebaseFirestore.instance.collection('tournaments').doc().id;
    Tournament tournament = Tournament(
      id: tournamentId,
      name: widget.title,
      teams: teams,
      matches: matches,
      started: true,
      finished: false,
    );

    // 4. Save to Firestore (optional, recommended)
    await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .set(tournament.toJson());

    // 5. Go to Tournament Overview
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentPageView(
          tournamentId: tournamentId,
          initialTournament: tournament,
        ),
      ),
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
        _selectedRules[tile.text] = !isSelected;
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
