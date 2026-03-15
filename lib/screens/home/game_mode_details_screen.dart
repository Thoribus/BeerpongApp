import 'dart:async';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/screens/home/game_lobby_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../util/firestoreservice.dart';
import '../../util/route_args.dart';
import '../../util/user_provider.dart';
import '../../models/user.dart';
import '../../models/player.dart';
import 'package:go_router/go_router.dart';
import '../../models/team.dart';
import '../../models/cup.dart';

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
  // ----- UI-only state -----
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final PageController _bottomPageController = PageController();
  int _bottomCurrentPage = 0;

  final List<String> infoPages = [
    'Fast-paced fun for everyone!',
    'Pick the rules you want to use!',
    'Invite your friends for a challenge!',
  ];

  final List<_InfoTileData> tiles = [
    _InfoTileData(BeerpongIcons.airball, 'Airballs'),
    _InfoTileData(Icons.roundabout_left, 'Bounce'),
    _InfoTileData(Icons.sports_basketball_outlined, 'Putback'),
    _InfoTileData(BeerpongIcons.palmTree, 'Island'),
    _InfoTileData(BeerpongIcons.skull, 'Deathcup'),
    _InfoTileData(BeerpongIcons.umstellen, 'Rearrange'),
  ];

  late GameLobbyController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = GameLobbyController(
      initialRules: {for (final tile in tiles) tile.text: false},
    );
    _ctrl.addListener(_onControllerChanged);
    _ctrl.onShowMessage = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    };
    _ctrl.onInvitationDeclined = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      }
    };
    _ctrl.createGameDoc();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _pageController.dispose();
    _bottomPageController.dispose();
    super.dispose();
  }

  // ----- Context-dependent orchestration -----

  Future<void> _onPickFriend(bool isBlue, int rowIndex) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user logged in!')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final friends = await FirestoreService.instance.getFriends(currentUser.id);
    if (!mounted) return;
    if (friends.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No friends found!')));
      return;
    }
    final selected = await _showPickPlayerDialog(currentUser, friends);
    if (selected == null) return;

    if (selected.id == currentUser.id) {
      await _ctrl.selectSelf(isBlue, rowIndex, selected);
    } else {
      await _ctrl.sendInvitation(
        isBlue: isBlue,
        rowIndex: rowIndex,
        fromUserId: currentUser.id,
        selected: selected,
      );
      messenger.showSnackBar(SnackBar(content: Text('Invited ${selected.username}')));
    }
  }

  Future<User?> _showPickPlayerDialog(User currentUser, List<User> friends) async {
    final completer = Completer<User?>();
    final bodyWidget = _buildPickPlayerBody(currentUser, friends, completer);
    await showDialog<User?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[850],
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(12),
          child: bodyWidget,
        ),
      ),
    );
    return completer.future;
  }

  Future<void> _onStartGame() async {
    if (_ctrl.gameId == null) return;
    final chosenTeam = await _showStartingTeamDialog();
    if (chosenTeam == null) return;

    for (final inviteId in _ctrl.acceptedInvites) {
      await FirestoreService.instance.updateInvitationGameId(inviteId, _ctrl.gameId!);
    }
    await _ctrl.startGame(chosenTeam);
    if (!mounted) return;

    final team1 = Team(
      color: Colors.blue,
      players: _ctrl.playersBlue,
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
    );
    final team2 = Team(
      color: Colors.red,
      players: _ctrl.playersRed,
      cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
    );
    context.pushReplacement(
      '/game',
      extra: GameArgs(
        id: _ctrl.gameId!,
        team1: team1,
        team2: team2,
        selectedRules: _ctrl.selectedRules,
        invitations: _ctrl.acceptedInvites,
        startingTeam: _ctrl.startingTeam == 'Team Blue',
        tournamentId: '',
      ),
    );
  }

  Future<String?> _showStartingTeamDialog() async {
    const team1Name = 'Team Blue';
    const team2Name = 'Team Red';
    final team1Players =
        _ctrl.playersBlue.map((p) => p.name).where((n) => n.isNotEmpty).toList();
    final team2Players =
        _ctrl.playersRed.map((p) => p.name).where((n) => n.isNotEmpty).toList();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      ...team1Players.map((n) => Text(n)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(team2Name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
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
      ),
    );
  }

  // ----- UI Build Methods -----

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
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                        SvgPicture.asset(widget.iconPath, height: 100),
                        const SizedBox(height: 16),
                        Text(
                          infoPages[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
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
                        color: _currentPage == index ? Colors.white : Colors.white30,
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
                      SingleChildScrollView(child: _buildLobbySection()),
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
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _ctrl.canStartGame() ? _onStartGame : null,
                child: const Text(
                  'Start Game',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
    final teamName = isBlue ? 'TEAM BLUE' : 'TEAM RED';
    final color = isBlue ? Colors.blue : Colors.red;
    final players = isBlue ? _ctrl.playersBlue : _ctrl.playersRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            teamName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(
              players.length,
              (index) => _buildPlayerRow(isBlue: isBlue, rowIndex: index),
            ),
          ),
          if (players.length < 4) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _ctrl.addPlayer(isBlue),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Player', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerRow({required bool isBlue, required int rowIndex}) {
    final players = isBlue ? _ctrl.playersBlue : _ctrl.playersRed;
    final invitationStatuses =
        isBlue ? _ctrl.blueInvitationStatuses : _ctrl.redInvitationStatuses;
    final status = invitationStatuses[rowIndex];
    final player = players[rowIndex];
    final hasPickedFriendOrSelf = player.user != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () => _ctrl.removePlayer(isBlue, rowIndex),
      ),
      title: hasPickedFriendOrSelf
          ? _buildReadOnlyLabel(player)
          : _buildEditableField(isBlue, players, rowIndex),
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
            const Text('pending...', style: TextStyle(color: Colors.amber)),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _ctrl.cancelInvitation(isBlue, rowIndex),
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

  Widget _buildEditableField(bool isBlue, List<Player> players, int rowIndex) {
    return TextFormField(
      initialValue: players[rowIndex].name,
      onChanged: (val) => _ctrl.updatePlayerName(isBlue, rowIndex, val),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        fillColor: Colors.white10,
        filled: true,
        labelText: 'Player ${rowIndex + 1}',
        labelStyle: const TextStyle(color: Colors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const Divider(color: Colors.white24),
          _buildPlayerOptionCard(
            currentUser,
            completer,
            label: 'Yourself',
            icon: Icons.star,
            iconColor: Colors.amber,
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Friends', style: TextStyle(color: Colors.white70)),
          ),
          ...friends.map((friend) => _buildPlayerOptionCard(friend, completer)),
        ],
      ),
    );
  }

  Widget _buildPlayerOptionCard(
    User user,
    Completer<User?> completer, {
    String? label,
    IconData icon = Icons.person,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white12,
        child: Icon(icon, color: iconColor),
      ),
      title: Text(label ?? user.username, style: const TextStyle(color: Colors.white)),
      onTap: () {
        if (!completer.isCompleted) completer.complete(user);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildSelectableTile(int index) {
    final tile = tiles[index];
    final isSelected = _ctrl.selectedRules[tile.text] == true;

    return GestureDetector(
      onTap: () => _ctrl.toggleRule(tile.text, !isSelected),
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
            Icon(tile.icon, color: isSelected ? Colors.amber[800] : Colors.grey),
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
