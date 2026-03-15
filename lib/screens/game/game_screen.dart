import 'dart:async';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/screens/game/game_controller.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/team.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.id,
    required this.team1,
    required this.team2,
    required this.selectedRules,
    required this.startingTeam,
    required this.invitations,
    required this.tournamentId,
  });

  final String id;
  final Team team1;
  final Team team2;
  final Map<String, bool> selectedRules;
  final bool startingTeam;
  final List<String> invitations;
  final String tournamentId;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late GameController _ctrl;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Future<void> _loadGameFuture;
  bool _showExpandedButtons = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _ctrl = GameController(userProvider);
    _ctrl.addListener(_onControllerChanged);
    _loadGameFuture = _ctrl.loadGameState(
      widgetId: widget.id,
      widgetTeam1: widget.team1,
      widgetTeam2: widget.team2,
      widgetStartingTeam: widget.startingTeam,
      widgetInvitations: widget.invitations,
      widgetSelectedRules: widget.selectedRules,
      widgetTournamentId: widget.tournamentId,
    );
    _pageController.addListener(_handlePageChange);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(_ctrl.persistIfNotEnded());
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    final pageIndex = _pageController.page?.round() ?? 0;
    if (_currentPage != pageIndex) {
      setState(() => _currentPage = pageIndex);
    }
  }

  // ----- Cup tap orchestration -----

  void onCupTap(int cupIndex) {
    if (_ctrl.islandShotActive) {
      // Only yellow (highlighted island) cups trigger the island shot power.
      // Tapping a non-island cup during island mode is treated as a normal hit.
      final cup = _ctrl.currentTeam.cups
          .where((c) => c.index == cupIndex)
          .firstOrNull;
      if (cup != null && cup.color == Colors.yellow) {
        handleIslandShot(cupIndex);
      } else {
        showPlayerSelectionDialog(context, cupIndex);
      }
    } else {
      showPlayerSelectionDialog(context, cupIndex);
    }
  }

  Future<void> showPlayerSelectionDialog(BuildContext ctx, int cupIndex) async {
    await DialogHelpers.showSelectionDialog(
      ctx,
      'Select Player',
      _ctrl.currentTeam.currentPlayers,
      (player) => _handleNormalHit(player, cupIndex),
    );
  }

  // ----- Island orchestration -----

  Future<void> _highlightIslandCups() async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player',
      _ctrl.currentTeam.currentPlayers.where((p) => !p.islandShotUsed).toList(),
      (player) {
        _ctrl.saveCurrentState();
        _ctrl.selectIslandShooter(player);
      },
    );
  }

  Future<void> handleIslandShot(int cupIndex) async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Select Player and Shot Result',
      _ctrl.currentTeam.currentPlayers,
      (player) {
        _ctrl.addEvent('Island Shot', _ctrl.currentTeam, player);
        _ctrl.saveCurrentState();
        if (player == _ctrl.currentIslandShooter) {
          // Island power shot: hit the cup + a random bonus cup
          _ctrl.toggleIslandCups();
          _ctrl.currentIslandShooter = null;
          _ctrl.incrementPlayerScore(player);
          _ctrl.addCupToPlayer(player, cupIndex);
          _ctrl.incrementPlayerHitThisRound(player);
          _ctrl.incrementPlayerThrows(player);
          _ctrl.handleCupHit(cupIndex, context);
          try {
            final extraIndex = _ctrl.getRandomCupIndex(
                _ctrl.currentTeam.cups, cupIndex, _ctrl.currentTeam.color);
            _ctrl.handleCupHit(extraIndex, context);
            _ctrl.addCupToPlayer(player, extraIndex);
            _ctrl.incrementPlayerScore(player);
          } catch (_) {
            debugPrint('No matching cups found for island shot bonus.');
          }
        } else {
          _ctrl.incrementPlayerScore(player);
          _ctrl.addCupToPlayer(player, cupIndex);
          _ctrl.incrementPlayerHitThisRound(player);
          _ctrl.incrementPlayerThrows(player);
          _ctrl.handleCupHit(cupIndex, context);
          _ctrl.checkOnFire(player, context);
        }
        _checkGameEnd(player, cupIndex);
      },
    );
  }

  // ----- Hit handlers -----

  void _handleNormalHit(Player player, int cupIndex) {
    _ctrl.addEvent('Normal Hit', _ctrl.currentTeam, player);
    _ctrl.saveCurrentState();
    _ctrl.addCupToPlayer(player, cupIndex);
    _ctrl.incrementPlayerThrows(player);
    _ctrl.incrementPlayerHitThisRound(player);
    _ctrl.incrementPlayerScore(player);
    _ctrl.handleCupHit(cupIndex, context);
    _ctrl.checkOnFire(player, context);
    _checkGameEnd(player, cupIndex);
  }

  void _handleDeathCup(Player player) {
    _ctrl.addEvent('Death Cup', _ctrl.currentTeam, player);
    _ctrl.saveCurrentState();
    for (final cup in _ctrl.currentTeam.cups) {
      if (cup.color == _ctrl.currentTeam.color) {
        _ctrl.addCupToPlayer(player, cup.index);
        _ctrl.handleCupHit(cup.index, context);
        _ctrl.incrementPlayerScore(player);
        _ctrl.incrementPlayerThrows(player);
      }
    }
    _checkGameEnd(player, 11);
  }

  // ----- Game end orchestration -----

  void _checkGameEnd(Player player, int cupIndex) async {
    if (!_ctrl.areAllCupsGone()) return;

    if (_ctrl.selectedRules['Putback'] == true && cupIndex != 11) {
      final enemyHit = await _handleNachwurf(cupIndex);
      if (enemyHit) {
        _ctrl.decrementPlayerScore(player);
        return;
      }
    }

    _ctrl.setGameEnded();
    _ctrl.setPlayerHitLastCup(player);

    await GamePersistence.clearGameState(false);
    await _ctrl.saveGameStatistics();

    if (!mounted) return;

    if (_ctrl.tournamentId != '') {
      final match = TournamentMatch(
        id: _ctrl.id,
        team1: _ctrl.team1,
        team2: _ctrl.team2,
        winner: _ctrl.winner == 'Team 1' ? _ctrl.team1 : _ctrl.team2,
        played: true,
        selectedRules: _ctrl.selectedRules,
        invitations: _ctrl.invitations,
      );
      context.pop({'match': match});
      return;
    }

    await DialogHelpers.showGameEndDialog(context, _ctrl.currentTeam.players);
  }

  Future<bool> _handleNachwurf(int cupIndex) async {
    final enemyTeam = (_ctrl.currentTeam == _ctrl.team1) ? _ctrl.team2 : _ctrl.team1;
    final chosenPlayer = await DialogHelpers.showNachwurfSelectionDialog(
      context,
      'Enemy Team\'s Last Turn',
      enemyTeam.players,
    );
    if (chosenPlayer != null) {
      chosenPlayer.defended++;
      _ctrl.addEvent('Defended', _ctrl.currentTeam, chosenPlayer);
      _ctrl.saveCurrentState();
      _ctrl.removeLastCupHit(cupIndex);
      return true;
    }
    return false;
  }

  // ----- UI Build Methods -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _loadGameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                _buildTopNavButtons(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCurrentGamePage(),
                      _buildGameStatsPage(_ctrl.currentTeam.color),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Current Game',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: AppTheme.gold,
      actions: [
        IconButton(
          icon: const Icon(Icons.scatter_plot_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTopNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _currentPage == 0 ? null : () => _pageController.jumpToPage(0),
          child: Text(
            'View Table',
            style: TextStyle(color: _currentPage == 0 ? Colors.amber : Colors.white),
          ),
        ),
        const VerticalDivider(color: Colors.white, width: 20, thickness: 2),
        TextButton(
          onPressed: _currentPage == 1 ? null : () => _pageController.jumpToPage(1),
          child: Text(
            'View Game Stats',
            style: TextStyle(color: _currentPage == 1 ? Colors.amber : Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentGamePage() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            top: 100.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.2),
                    Colors.grey.shade600,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: CupLayout.buildCupsArea(
                      team: _ctrl.currentTeam,
                      onCupTap: onCupTap,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _ctrl.currentTeam.currentPlayers.length.clamp(0, 4),
                      itemBuilder: (context, index) {
                        return _buildPlayerName(_ctrl.currentTeam.currentPlayers[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              width: constraints.maxWidth - 32.0,
              height: 77.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white, width: 2.0),
                gradient: LinearGradient(
                  colors: [
                    _ctrl.currentTeam == _ctrl.team1
                        ? _ctrl.team2.color
                        : _ctrl.team1.color,
                    Colors.grey,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: WaterSplashAnimation(splashColor: Colors.white),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: FloatingActionButton.extended(
                        heroTag: 'airball',
                        onPressed: () => DialogHelpers.showAirballPlayerSelectionDialog(
                          context,
                          _ctrl.currentTeam,
                          (player) => _ctrl.handleAirballRule(player, context),
                        ),
                        tooltip: 'Airball',
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        label: const Text(
                          'Airball Area',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPlayerName(Player player) {
    return TweenAnimationBuilder<Alignment>(
      tween: AlignmentTween(
        begin: _ctrl.beginAlignment,
        end: _ctrl.endAlignment,
      ),
      duration: const Duration(seconds: 5),
      onEnd: _ctrl.toggleGradientDirection,
      builder: (context, alignment, child) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_ctrl.currentTeam.color, Colors.grey.shade600],
              begin: alignment,
              end: Alignment.center,
            ),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              player.user == null
                  ? const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          player.user!.mapAvatarKeyToAsset(),
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.length > 13
                          ? '${player.name.substring(0, 12)}...'
                          : player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Level: 1',
                      style: TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameStatsPage(Color teamColor) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Actions',
                style: TextStyle(
                    color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildGameActions(_ctrl.currentTeam.players),
              const SizedBox(height: 10),
              const Text(
                'Team Statistics',
                style: TextStyle(
                    color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTeamBrackets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameActions(List<Player> players) {
    final actions = [
      {
        'actionTitle': 'Bitchcup',
        'progressText': 'loosen your belt',
        'teamColor': _ctrl.currentTeam.color,
        'playerName': players[0].name,
        'teamName': 'Team Blue',
        'playerIcon': Icons.dry_cleaning_outlined,
        'progressValue': 0.7,
        'isActive': false,
      },
      {
        'actionTitle': 'On fire',
        'progressText': 'get your balls back',
        'teamColor': _ctrl.currentTeam.color,
        'playerName': players[0].name,
        'teamName': '2 in a row',
        'playerIcon': Icons.local_fire_department,
        'progressValue': 0.7,
        'isActive': true,
      },
      {
        'actionTitle': '3rd Airball',
        'progressText': '1 airball until shot',
        'teamColor': _ctrl.currentTeam.color,
        'playerName': players[0].name,
        'teamName': 'Team Red',
        'playerIcon': BeerpongIcons.airball,
        'progressValue': 0.5,
        'isActive': false,
      },
      {
        'actionTitle': 'Island',
        'progressText': 'One hit for two cups',
        'teamColor': _ctrl.currentTeam.color,
        'playerName': players[0].name,
        'teamName': '2 ready',
        'playerIcon': BeerpongIcons.palmTree,
        'progressValue': 0.8,
        'isActive': _ctrl.currentTeam.canIslandShot,
      },
    ];

    return Column(
      children: actions
          .where((action) => action['isActive'] == true)
          .map((action) => _buildActionBracket(action))
          .toList(),
    );
  }

  Widget _buildActionBracket(Map<String, dynamic> actionData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amberAccent, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionData['actionTitle'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: actionData['progressText'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: actionData['teamColor'],
                        ),
                      ),
                      const TextSpan(
                        text: ' - ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      TextSpan(
                        text: '${actionData['playerName']} is making a move',
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (actionData['teamColor'] as Color).withValues(alpha: 0.2),
                child: Icon(actionData['playerIcon'], color: actionData['teamColor']),
              ),
              const SizedBox(height: 4),
              Text(
                actionData['teamName'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBrackets() {
    return Column(
      children: [
        _buildTeamBracket('Team Blue', Colors.blue, _ctrl.team1.players),
        const SizedBox(height: 20),
        _buildTeamBracket('Team Red', Colors.red, _ctrl.team2.players),
      ],
    );
  }

  Widget _buildTeamBracket(String teamName, Color color, List<Player> players) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Table(
              border: const TableBorder.symmetric(
                  outside: BorderSide.none, inside: BorderSide.none),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2)),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Player',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('S',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('A',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('T',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('M',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
                ...players.map((player) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(player.name,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.score}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.airballs}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.throws}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${player.misses}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.transparent,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(
                  onPressed: _ctrl.undoLastAction,
                  tooltip: 'Undo last move',
                  icon: Icons.undo,
                  label: 'undo',
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildBottomButton(
                  onPressed: () => _ctrl.toggleRearranged(context),
                  tooltip: 'Rearrange cups',
                  icon: Icons.workspaces_outlined,
                  label: 'cups',
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildBottomButton(
                  onPressed: () {
                    setState(() => _showExpandedButtons = !_showExpandedButtons);
                  },
                  tooltip: 'More Options',
                  icon: Icons.scatter_plot_outlined,
                  label: 'action',
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildBottomButton(
                  onPressed: () => DialogHelpers.confirmEndTurn(context, _ctrl),
                  tooltip: 'End turn',
                  icon: Icons.check_rounded,
                  label: 'end',
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ],
            ),
          ),
          if (_showExpandedButtons)
            GestureDetector(
              onTap: () {
                setState(() => _showExpandedButtons = false);
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_ctrl.selectedRules['Deathcup'] == true)
                        _buildExpandedButton(
                          onPressed: () => DialogHelpers.showDeathcupSelectionDialog(
                            context,
                            _ctrl.currentTeam,
                            (player) => _handleDeathCup(player),
                          ),
                          tooltip: 'Deathcup',
                          icon: BeerpongIcons.skull,
                          color: _ctrl.currentTeam == _ctrl.team1
                              ? _ctrl.team2.color
                              : _ctrl.team1.color,
                        ),
                      const SizedBox(width: 20),
                      _buildExpandedButton(
                        onPressed: () => _ctrl.toggleRearranged(context),
                        tooltip: 'Rearrange the cups.',
                        icon: Icons.scatter_plot_outlined,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 20),
                      if (_ctrl.selectedRules['Island'] == true)
                        _buildExpandedButton(
                          onPressed: _ctrl.currentTeam.canIslandShot &&
                                  _ctrl.currentTeam.cups
                                      .any((c) => c.isVisible && _ctrl.isIslandCup(c))
                              ? _highlightIslandCups
                              : null,
                          tooltip: 'Island Cup',
                          icon: BeerpongIcons.palmTree,
                          color: _ctrl.islandBackgroundColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedButton({
    required VoidCallback? onPressed,
    required String tooltip,
    required IconData icon,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: color,
        heroTag: tooltip,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2.0),
        ),
        child: Icon(icon, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildBottomButton({
    required VoidCallback onPressed,
    required String tooltip,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: onPressed,
        heroTag: label.isEmpty ? 'undo' : label.toLowerCase(),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: label.isEmpty
                ? Icon(icon, size: 30, color: Colors.white)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 30, color: Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ----- Water Splash Animation -----

class WaterSplashAnimation extends StatefulWidget {
  final Color splashColor;
  const WaterSplashAnimation({super.key, this.splashColor = Colors.blue});

  @override
  State<WaterSplashAnimation> createState() => _WaterSplashAnimationState();
}

class _WaterSplashAnimationState extends State<WaterSplashAnimation> {
  final List<WaterSplash> _splashes = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _addSplash);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _addSplash(Timer timer) {
    if (!mounted) return;
    if (_splashes.length >= 20) return; // safety cap
    final splash = WaterSplash(x: Random().nextDouble(), y: Random().nextDouble());
    setState(() {
      _splashes.add(splash);
    });
    // Remove this splash after its 2-second TweenAnimationBuilder duration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _splashes.remove(splash);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _splashes
          .map((splash) => Positioned(
                left: splash.x * MediaQuery.of(context).size.width,
                top: splash.y * MediaQuery.of(context).size.height,
                child: _buildSplashEffect(),
              ))
          .toList(),
    );
  }

  Widget _buildSplashEffect() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 2),
      tween: Tween<double>(begin: 1.0, end: 0.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: Container(
              width: 50 * value,
              height: 50 * value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.splashColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaterSplash {
  final double x, y;
  WaterSplash({required this.x, required this.y});
}
