import 'dart:async';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../util/firestoreservice.dart';
import '../../util/user_provider.dart';
import '../../models/user.dart';
import '../../models/player.dart';
import '../../screens/tournament/tournament_lobby_controller.dart';

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

  late TournamentLobbyController _ctrl;

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

  @override
  void initState() {
    super.initState();
    _ctrl = TournamentLobbyController(
      initialRules: {for (var tile in tiles) tile.text: false},
    );
    _ctrl.addListener(_onControllerChanged);
    _ctrl.onShowMessage = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    };
    _ctrl.onInvitationDeclined = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined')),
        );
      }
    };
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
    final players = _ctrl.players;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            'Players',
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
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _ctrl.addPlayer,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Player',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerRow({required int rowIndex}) {
    final status = _ctrl.invitationStatuses[rowIndex];
    final player = _ctrl.players[rowIndex];
    final hasPickedFriendOrSelf = (player.user != null);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () => _ctrl.removePlayer(rowIndex),
      ),
      title: hasPickedFriendOrSelf
          ? _buildReadOnlyLabel(player)
          : _buildEditableField(rowIndex),
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
            const Text('pending...', style: TextStyle(color: Colors.amber)),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                await _ctrl.cancelInvitation(rowIndex);
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

  Widget _buildEditableField(int rowIndex) {
    return TextFormField(
      initialValue: _ctrl.players[rowIndex].name,
      onChanged: (val) => _ctrl.updatePlayerName(rowIndex, val),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        fillColor: Colors.white10,
        filled: true,
        labelText: 'Player ${rowIndex + 1}',
        labelStyle: const TextStyle(color: Colors.amber),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
    final messenger = ScaffoldMessenger.of(context);
    final friends = await FirestoreService.instance.getFriends(currentUser.id);
    if (!mounted) return;
    if (friends.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No friends found!')),
      );
      return;
    }
    final selected = await _showPickPlayerDialog(currentUser, friends);
    if (!mounted) return;
    if (selected == null) return;
    if (selected.id == currentUser.id) {
      _ctrl.selectPlayer(rowIndex, selected);
      return;
    }
    await _ctrl.sendInvitation(rowIndex, currentUser.id, selected);
    if (!mounted) return;
    messenger.showSnackBar(
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
                currentUser, 'You', Icons.account_circle, Colors.amber),
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
                    friend, 'Friend', Icons.person, Colors.blue),
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
        color: color.withValues(alpha: 0.1),
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

  bool _canStartTournament() => _ctrl.canStartTournament();

  Future<void> _onStartTournament() async {
    final tournament = await _ctrl.createTournament(widget.title);
    if (!mounted) return;
    context.pushReplacement(
      '/tournament/${tournament.id}',
      extra: TournamentPageViewArgs(
        tournamentId: tournament.id,
        initialTournament: tournament,
      ),
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
