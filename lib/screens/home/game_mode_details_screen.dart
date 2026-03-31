import 'dart:async';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/screens/home/game_lobby_controller.dart';
import 'package:beerpongapp/screens/tournament/tournament_lobby_controller.dart';
import 'package:beerpongapp/theme.dart';
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
  final String iconPath;
  final Color color;
  final bool isTournament;

  const GameModeDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.color,
    this.isTournament = false,
  });

  @override
  State<GameModeDetailsScreen> createState() => _GameModeDetailsScreenState();
}

class _GameModeDetailsScreenState extends State<GameModeDetailsScreen> {
  static const _ruleDefs = [
    (BeerpongIcons.airball, 'Airballs'),
    (Icons.roundabout_left, 'Bounce'),
    (Icons.sports_basketball_outlined, 'Putback'),
    (BeerpongIcons.palmTree, 'Island'),
    (BeerpongIcons.skull, 'Deathcup'),
    (BeerpongIcons.umstellen, 'Rearrange'),
  ];

  late bool _isTournament;

  // Exactly one is non-null at any time
  GameLobbyController? _gameCtrl;
  TournamentLobbyController? _tournCtrl;

  Map<String, bool> get _selectedRules =>
      _isTournament ? _tournCtrl!.selectedRules : _gameCtrl!.selectedRules;

  bool get _canStart => _isTournament
      ? _tournCtrl!.canStartTournament()
      : _gameCtrl!.canStartGame();

  /// Accent color: purple for tournament mode, the card color for single game.
  Color get _activeColor =>
      _isTournament ? Colors.deepPurple : widget.color;

  /// Maps English rule map-key → localized display name.
  /// The English keys must stay unchanged for game logic lookups.
  String _ruleDisplayName(String key) => switch (key) {
        'Airballs' => context.loc.gameModeRuleAirballs,
        'Bounce' => context.loc.gameModeRuleBounce,
        'Putback' => context.loc.gameModeRulePutback,
        'Island' => context.loc.gameModeRuleIsland,
        'Deathcup' => context.loc.gameModeRuleDeathcup,
        'Rearrange' => context.loc.gameModeRuleRearrange,
        _ => key,
      };

  @override
  void initState() {
    super.initState();
    _isTournament = widget.isTournament;
    _initController();
  }

  void _initController() {
    final rules = {for (final r in _ruleDefs) r.$2: false};
    if (_isTournament) {
      _tournCtrl = TournamentLobbyController(initialRules: rules);
      _tournCtrl!.addListener(_onControllerChanged);
      _tournCtrl!.onShowMessage = _showMessage;
      _tournCtrl!.onInvitationDeclined = _onInvitationDeclined;
    } else {
      _gameCtrl = GameLobbyController(initialRules: rules);
      _gameCtrl!.addListener(_onControllerChanged);
      _gameCtrl!.onShowMessage = _showMessage;
      _gameCtrl!.onInvitationDeclined = _onInvitationDeclined;
      _gameCtrl!.createGameDoc();
    }
  }

  void _disposeController() {
    _gameCtrl?.removeListener(_onControllerChanged);
    _gameCtrl?.dispose();
    _gameCtrl = null;
    _tournCtrl?.removeListener(_onControllerChanged);
    _tournCtrl?.dispose();
    _tournCtrl = null;
  }

  void _switchMode(bool toTournament) {
    if (_isTournament == toTournament) return;
    setState(() {
      _disposeController();
      _isTournament = toTournament;
      _initController();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _onInvitationDeclined() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.gameModeInvitationDeclined)),
      );
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  // ----- Friend picking -----

  Future<void> _onPickFriend({required bool isBlue, required int rowIndex}) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) {
      _showMessage(context.loc.gameModeNoUser);
      return;
    }
    final friends = await FirestoreService.instance.getFriends(currentUser.id);
    if (!mounted) return;
    if (friends.isEmpty) {
      _showMessage(context.loc.gameModeNoFriends);
      return;
    }
    final selected = await _showPickPlayerDialog(currentUser, friends);
    if (!mounted || selected == null) return;

    if (_isTournament) {
      if (selected.id == currentUser.id) {
        _tournCtrl!.selectPlayer(rowIndex, selected);
      } else {
        await _tournCtrl!.sendInvitation(
          rowIndex,
          currentUser.id,
          selected,
          fromUsername: currentUser.username,
        );
        if (mounted) _showMessage(context.loc.gameModeInvited(selected.username));
      }
    } else {
      if (selected.id == currentUser.id) {
        await _gameCtrl!.selectSelf(isBlue, rowIndex, selected);
      } else {
        await _gameCtrl!.sendInvitation(
          isBlue: isBlue,
          rowIndex: rowIndex,
          fromUserId: currentUser.id,
          fromUsername: currentUser.username,
          selected: selected,
        );
        if (mounted) _showMessage(context.loc.gameModeInvited(selected.username));
      }
    }
  }

  Future<User?> _showPickPlayerDialog(User currentUser, List<User> friends) async {
    final c = AppColors.of(context);
    final completer = Completer<User?>();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text(
                      context.loc.gameModeDialogSelectPlayer,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.onBackground,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: c.subtle),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: c.divider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    _playerOptionTile(currentUser, completer, c,
                        label: context.loc.gameModeYourself, iconColor: Colors.amber),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Text(context.loc.gameModeFriends,
                          style: TextStyle(color: c.subtle, fontSize: 12)),
                    ),
                    ...friends.map((f) => _playerOptionTile(f, completer, c)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return completer.future;
  }

  Widget _playerOptionTile(User user, Completer<User?> completer, AppColors c,
      {String? label, Color iconColor = Colors.transparent}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: c.chip,
        child: ClipOval(
          child: user.mapAvatarKeyToAsset().isEmpty
              ? const Icon(Icons.person, color: Colors.white54, size: 20)
              : SvgPicture.asset(
                  user.mapAvatarKeyToAsset(),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
        ),
      ),
      title: Text(user.username,
          style: TextStyle(color: c.onBackground, fontWeight: FontWeight.w600)),
      subtitle: label != null
          ? Text(label, style: TextStyle(color: c.subtle, fontSize: 12))
          : null,
      onTap: () {
        if (!completer.isCompleted) completer.complete(user);
        Navigator.of(context).pop();
      },
    );
  }

  // ----- Start actions -----

  Future<void> _onStart() async {
    if (_isTournament) {
      await _onStartTournament();
    } else {
      await _onStartGame();
    }
  }

  Future<void> _onStartGame() async {
    if (_gameCtrl!.gameId == null) return;
    final hostId = Provider.of<UserProvider>(context, listen: false).user?.id;
    final chosenTeam = await _showStartingTeamDialog();
    if (chosenTeam == null) return;

    for (final inviteId in _gameCtrl!.acceptedInvites) {
      await FirestoreService.instance
          .updateInvitationGameId(inviteId, _gameCtrl!.gameId!);
    }
    await _gameCtrl!.startGame(chosenTeam, hostUserId: hostId);
    if (!mounted) return;

    context.pushReplacement(
      '/game',
      extra: GameArgs(
        id: _gameCtrl!.gameId!,
        team1: Team(
          color: Colors.blue,
          players: _gameCtrl!.playersBlue,
          cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
        ),
        team2: Team(
          color: Colors.red,
          players: _gameCtrl!.playersRed,
          cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
        ),
        selectedRules: _gameCtrl!.selectedRules,
        invitations: _gameCtrl!.acceptedInvites,
        startingTeam: _gameCtrl!.startingTeam == 'Team Blue',
        tournamentId: '',
      ),
    );
  }

  Future<void> _onStartTournament() async {
    final tournament = await _tournCtrl!.createTournament(widget.title);
    if (!mounted) return;
    context.pushReplacement(
      '/tournament/${tournament.id}',
      extra: TournamentPageViewArgs(
        tournamentId: tournament.id,
        initialTournament: tournament,
      ),
    );
  }

  Future<String?> _showStartingTeamDialog() {
    final blueNames = _gameCtrl!.playersBlue
        .map((p) => p.name)
        .where((n) => n.isNotEmpty)
        .toList();
    final redNames = _gameCtrl!.playersRed
        .map((p) => p.name)
        .where((n) => n.isNotEmpty)
        .toList();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.loc.gameModeWhoStarts),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(context.loc.labelTeamBlue,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      ...blueNames.map((n) => Text(n)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(context.loc.labelVs,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(context.loc.labelTeamRed,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      ...redNames.map((n) => Text(n)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.loc.gameModeWhichTeamStarts),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('Team Blue'),
            child: Text(context.loc.gameModeTeamBlueStarts,
                style: const TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('Team Red'),
            child: Text(context.loc.gameModeTeamRedStarts,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ----- Build -----

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final startLabel = _isTournament ? context.loc.gameModeBtnStartTournament : context.loc.gameModeBtnStartGame;

    return Scaffold(
      backgroundColor: _activeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Hero
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  widget.iconPath,
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Mode toggle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: _buildModeToggle(c),
                  ),

                  // Merged scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(context.loc.labelRules, c),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                            children: List.generate(
                              _ruleDefs.length,
                              (i) => _buildRuleTile(i, c),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: c.divider),
                          const SizedBox(height: 16),
                          _sectionHeader(
                              _isTournament ? context.loc.labelPlayers : context.loc.labelTeams, c),
                          const SizedBox(height: 12),
                          _isTournament
                              ? _buildTournamentLobbyContent(c)
                              : _buildSingleGameLobbyContent(c),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Start button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canStart ? _activeColor : c.chip,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: _canStart ? 2 : 0,
                        ),
                        onPressed: _canStart ? _onStart : null,
                        child: Text(
                          startLabel,
                          style: TextStyle(
                            color: _canStart ? Colors.white : c.subtle,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(AppColors c) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _modeToggleButton(context.loc.gameModeToggleSingleGame, !_isTournament, () => _switchMode(false), c),
          _modeToggleButton(context.loc.labelTournament, _isTournament, () => _switchMode(true), c),
        ],
      ),
    );
  }

  Widget _modeToggleButton(
      String label, bool active, VoidCallback onTap, AppColors c) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? _activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : c.subtle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, AppColors c) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: c.onBackground,
      ),
    );
  }

  // ----- Rule tile -----

  Widget _buildRuleTile(int index, AppColors c) {
    final (icon, label) = _ruleDefs[index];
    final isSelected = _selectedRules[label] == true;
    return GestureDetector(
      onTap: () {
        if (_isTournament) {
          _tournCtrl!.toggleRule(label, !isSelected);
        } else {
          _gameCtrl!.toggleRule(label, !isSelected);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? _activeColor.withValues(alpha: 0.12) : c.chip,
          border: Border.all(
            color: isSelected ? _activeColor : c.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _activeColor : c.subtle, size: 26),
            const SizedBox(height: 6),
            Text(
              _ruleDisplayName(label),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? _activeColor : c.onBackground,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Single game lobby -----

  Widget _buildSingleGameLobbyContent(AppColors c) {
    final ctrl = _gameCtrl!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTeamPanel(
            c: c,
            color: Colors.blue,
            label: context.loc.gameModeLabelBlue,
            players: ctrl.playersBlue,
            statuses: ctrl.blueInvitationStatuses,
            isBlue: true,
            maxPlayers: 4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTeamPanel(
            c: c,
            color: Colors.red,
            label: context.loc.gameModeLabelRed,
            players: ctrl.playersRed,
            statuses: ctrl.redInvitationStatuses,
            isBlue: false,
            maxPlayers: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPanel({
    required AppColors c,
    required Color color,
    required String label,
    required List<Player> players,
    required Map<int, String> statuses,
    required bool isBlue,
    required int maxPlayers,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            players.length,
            (i) => _buildPlayerRow(
              c: c,
              player: players[i],
              status: statuses[i],
              onAdd: () => _onPickFriend(isBlue: isBlue, rowIndex: i),
              onRemove: () => _gameCtrl!.removePlayer(isBlue, i),
              onNameChanged: (val) =>
                  _gameCtrl!.updatePlayerName(isBlue, i, val),
              onCancelInvite: () => _gameCtrl!.cancelInvitation(isBlue, i),
              hintText: 'Player ${i + 1}',
            ),
          ),
          if (players.length < maxPlayers) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _gameCtrl!.addPlayer(isBlue),
              icon: Icon(Icons.add, color: color, size: 16),
              label: Text(context.loc.btnAdd, style: TextStyle(color: color, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----- Tournament lobby -----

  Widget _buildTournamentLobbyContent(AppColors c) {
    final ctrl = _tournCtrl!;
    final players = ctrl.players;
    return Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _activeColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _activeColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.loc.gameModeLabelPlayersUpper,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _activeColor,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              players.length,
              (i) => _buildPlayerRow(
                c: c,
                player: players[i],
                status: ctrl.invitationStatuses[i],
                onAdd: () => _onPickFriend(isBlue: true, rowIndex: i),
                onRemove: () => ctrl.removePlayer(i),
                onNameChanged: (val) => ctrl.updatePlayerName(i, val),
                onCancelInvite: () => ctrl.cancelInvitation(i),
                hintText: context.loc.gameModePlayerN(i + 1),
              ),
            ),
            if (players.length < 8) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: ctrl.addPlayer,
                icon: Icon(Icons.add, color: _activeColor, size: 16),
                label: Text(context.loc.gameModeAddPlayer,
                    style: TextStyle(color: _activeColor, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: _activeColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
    );
  }

  // ----- Shared player row -----

  Widget _buildPlayerRow({
    required AppColors c,
    required Player player,
    required String? status,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required ValueChanged<String> onNameChanged,
    required VoidCallback onCancelInvite,
    required String hintText,
  }) {
    final hasUser = player.user != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: hasUser
                ? _readOnlyLabel(player.name, c)
                : _editableField(player.name, hintText, onNameChanged, c),
          ),
          if (!hasUser)
            _iconBtn(Icons.person_add_outlined, c.subtle, onAdd, size: 20),
          _iconBtn(Icons.close, Colors.red, onRemove, size: 18),
          if (status == 'pending') ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.amber),
            ),
            _iconBtn(Icons.cancel, Colors.red, onCancelInvite, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _readOnlyLabel(String name, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: c.chip, borderRadius: BorderRadius.circular(8)),
      child: Text(
        name,
        style: TextStyle(
            color: c.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _editableField(String value, String hint, ValueChanged<String> onChange,
      AppColors c) {
    return TextFormField(
      initialValue: value,
      onChanged: onChange,
      style: TextStyle(color: c.onBackground, fontSize: 13),
      decoration: InputDecoration(
        fillColor: c.chip,
        filled: true,
        hintText: hint,
        hintStyle: TextStyle(color: c.subtle, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
      {double size = 20}) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
    );
  }
}
