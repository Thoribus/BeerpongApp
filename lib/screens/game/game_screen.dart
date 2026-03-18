import 'dart:async';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/screens/game/game_controller.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:go_router/go_router.dart';

import '../../models/player.dart';
import '../../models/team.dart';
import '../../widgets/player_card_mini.dart';

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
  bool _gameLoaded = false;

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
    ).then((_) {
      if (mounted) setState(() => _gameLoaded = true);
    });
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
    if (_ctrl.bounceShotActive) {
      _handleBounceCupTap(cupIndex);
    } else if (_ctrl.islandShotActive) {
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
        player.islandAttempts++;
        if (player == _ctrl.currentIslandShooter) {
          // Island power shot: hit the cup + a random bonus cup
          _ctrl.toggleIslandCups();
          _ctrl.currentIslandShooter = null;
          player.islandMakes++;
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
    // Bomb: cup already green → middle cup stays on table, no score for it here.
    // Adjacent cup scores are awarded inside _checkProximity.
    final isBomb = _ctrl.currentTeam.cups
        .any((c) => c.index == cupIndex && c.color == Colors.green);
    if (!isBomb) _ctrl.incrementPlayerScore(player);
    _ctrl.handleCupHit(cupIndex, context);
    _ctrl.checkOnFire(player, context);
    _checkGameEnd(player, cupIndex);
  }

  /// Step 1 — choose which player is bouncing, then enter bounce-shot mode.
  Future<void> _handleBounceShot() async {
    await DialogHelpers.showSelectionDialog(
      context,
      'Bounce Shot — Select Thrower',
      _ctrl.currentTeam.currentPlayers,
      (player) {
        _ctrl.activateBounceShot(player);
      },
    );
  }

  /// Step 2 — called from [onCupTap] while bounce mode is active.
  void _handleBounceCupTap(int cupIndex) {
    final player = _ctrl.currentBounceShooter!;
    _ctrl.addEvent('Bounce Hit', _ctrl.currentTeam, player);
    _ctrl.saveCurrentState();
    _ctrl.bounceShotActive = false;
    _ctrl.currentBounceShooter = null;
    player.bounceAttempts++;
    player.bounceMakes++;
    _ctrl.incrementPlayerThrows(player);
    _ctrl.incrementPlayerHitThisRound(player);
    _ctrl.incrementPlayerScore(player);
    _ctrl.addCupToPlayer(player, cupIndex);
    _ctrl.handleCupHit(cupIndex, context);
    try {
      final extraIndex = _ctrl.getRandomCupIndex(
          _ctrl.currentTeam.cups, cupIndex, _ctrl.currentTeam.color);
      _ctrl.handleCupHit(extraIndex, context);
      _ctrl.addCupToPlayer(player, extraIndex);
      _ctrl.incrementPlayerScore(player);
    } catch (_) {}
    _ctrl.checkOnFire(player, context);
    _checkGameEnd(player, cupIndex);
  }

  void _handleDeathCup(Player player) {
    _ctrl.addEvent('Death Cup', _ctrl.currentTeam, player);
    _ctrl.saveCurrentState();
    player.deathCupHits++;
    // One throw triggered the death cup — count it once, not per remaining cup.
    _ctrl.incrementPlayerThrows(player);
    _ctrl.incrementPlayerHitThisRound(player);
    for (final cup in _ctrl.currentTeam.cups) {
      if (cup.color == _ctrl.currentTeam.color) {
        _ctrl.addCupToPlayer(player, cup.index);
        _ctrl.handleCupHit(cup.index, context);
        _ctrl.incrementPlayerScore(player);
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
    final updatedUser = await _ctrl.saveGameStatistics();

    if (!mounted) return;

    if (_ctrl.tournamentId != '') {
      if (updatedUser != null) await _ctrl.updateCurrentUser(updatedUser);
      if (!mounted) return;
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

    await DialogHelpers.showGameEndDialog(
      context,
      _ctrl.currentTeam.players,
      onNavigate: updatedUser != null ? () => _ctrl.updateCurrentUser(updatedUser) : null,
    );
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
                _buildTopNav(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCurrentGamePage(),
                      _buildGameStatsPage(),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _teamLabel(Team team) =>
      team == _ctrl.team1 ? 'Team 1' : 'Team 2';

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    if (!_gameLoaded) {
      return AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        centerTitle: true,
        title: const Text('Game', style: TextStyle(color: Colors.white)),
      );
    }

    if (_ctrl.bounceShotActive) {
      return AppBar(
        backgroundColor: Colors.orange.shade900,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tap the cup you sank',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: _ctrl.cancelBounceShot,
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      );
    }

    final teamName = _teamLabel(_ctrl.currentTeam);
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.grey.shade900,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ctrl.currentTeam.color,
              boxShadow: [
                BoxShadow(
                  color: _ctrl.currentTeam.color.withValues(alpha: 0.7),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$teamName's Turn",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Top nav: pill segmented control ──────────────────────────────────────

  Widget _buildTopNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildNavPill(label: 'Table', index: 0),
          _buildNavPill(label: 'Stats', index: 1),
        ],
      ),
    );
  }

  Widget _buildNavPill({required String label, required int index}) {
    final isSelected = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : () => _pageController.jumpToPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Game table page ───────────────────────────────────────────────────────

  Widget _buildCurrentGamePage() {
    return Column(
      children: [
        _buildScoreStrip(),
        _buildAirballZone(),
        Expanded(child: _buildTableContainer()),
      ],
    );
  }

  /// Shows cups-remaining count for both teams side-by-side.
  Widget _buildScoreStrip() {
    final t1Cups = _ctrl.team1.cups.where((c) => c.isVisible).length;
    final t2Cups = _ctrl.team2.cups.where((c) => c.isVisible).length;
    final t1Name = _teamLabel(_ctrl.team1);
    final t2Name = _teamLabel(_ctrl.team2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTeamScore(t1Name, _ctrl.team1.color, t1Cups,
              isActive: _ctrl.currentTeam == _ctrl.team1),
          const Spacer(),
          const Text('vs', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          _buildTeamScore(t2Name, _ctrl.team2.color, t2Cups,
              isActive: _ctrl.currentTeam == _ctrl.team2, reversed: true),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String name, Color color, int cupsLeft,
      {bool isActive = false, bool reversed = false}) {
    final nameWidget = Text(
      name,
      style: TextStyle(
        color: isActive ? color : Colors.white54,
        fontSize: 12,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final cupsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        10,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < cupsLeft ? color : Colors.white12,
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed
          ? [cupsWidget, const SizedBox(width: 8), nameWidget]
          : [nameWidget, const SizedBox(width: 8), cupsWidget],
    );
  }

  /// Tap-anywhere miss zone — replaces the old gradient FAB container.
  Widget _buildAirballZone() {
    final attackColor = (_ctrl.currentTeam == _ctrl.team1
            ? _ctrl.team2.color
            : _ctrl.team1.color)
        .withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () => DialogHelpers.showAirballPlayerSelectionDialog(
        context,
        _ctrl.currentTeam,
        (player) => _ctrl.handleAirballRule(player, context),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: attackColor, width: 1.5),
          color: attackColor.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.close_rounded, color: attackColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'Miss Zone — tap to log airball',
              style: TextStyle(color: attackColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Green felt table surface with cups and player cards.
  Widget _buildTableContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF0D3B14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
        ],
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
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white12,
          ),
          Expanded(
            flex: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.8,
              ),
              itemCount: _ctrl.currentTeam.currentPlayers.length.clamp(0, 4),
              itemBuilder: (context, index) {
                return PlayerCardMini(
                  player: _ctrl.currentTeam.currentPlayers[index],
                  teamColor: _ctrl.currentTeam.color,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Stats page ────────────────────────────────────────────────────────────

  Widget _buildGameStatsPage() {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Team Statistics',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTeamBrackets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBrackets() {
    return Column(
      children: [
        _buildTeamBracket(_teamLabel(_ctrl.team1), _ctrl.team1.color, _ctrl.team1.players),
        const SizedBox(height: 20),
        _buildTeamBracket(_teamLabel(_ctrl.team2), _ctrl.team2.color, _ctrl.team2.players),
      ],
    );
  }

  Widget _buildTeamBracket(String teamName, Color color, List<Player> players) {
    const headerStyle = TextStyle(color: Colors.white70, fontSize: 11);
    const cellStyle = TextStyle(color: Colors.white, fontSize: 12);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Team name header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  teamName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white12),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Player', style: headerStyle),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Score', style: headerStyle, textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Throws', style: headerStyle, textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Misses', style: headerStyle, textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('Airballs', style: headerStyle, textAlign: TextAlign.center),
                    ),
                  ],
                ),
                ...players.map((player) => TableRow(
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(player.name,
                              style: cellStyle, overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('${player.score.toInt()}',
                              style: cellStyle, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('${player.throws}',
                              style: cellStyle, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('${player.misses}',
                              style: cellStyle, textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('${player.airballs}',
                              style: cellStyle, textAlign: TextAlign.center),
                        ),
                      ],
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    if (!_gameLoaded) return const SizedBox.shrink();
    return BottomAppBar(
      color: Colors.grey.shade900,
      height: 68,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDockButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: _ctrl.undoLastAction,
          ),
          _buildDockButton(
            icon: Icons.workspaces_outlined,
            label: 'Cups',
            onTap: () => _ctrl.toggleRearranged(context),
          ),
          _buildDockButton(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: _showActionsSheet,
          ),
          _buildDockButton(
            icon: Icons.check_rounded,
            label: 'End Turn',
            onTap: () => DialogHelpers.confirmEndTurn(context, _ctrl),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final color = isPrimary ? Colors.amber : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (_ctrl.selectedRules['Deathcup'] == true)
                _buildSheetAction(
                  ctx: ctx,
                  icon: BeerpongIcons.skull,
                  label: 'Death Cup',
                  color: _ctrl.currentTeam == _ctrl.team1
                      ? _ctrl.team2.color
                      : _ctrl.team1.color,
                  onTap: () => DialogHelpers.showDeathcupSelectionDialog(
                    context,
                    _ctrl.currentTeam,
                    (player) => _handleDeathCup(player),
                  ),
                ),
              if (_ctrl.selectedRules['Island'] == true)
                _buildSheetAction(
                  ctx: ctx,
                  icon: BeerpongIcons.palmTree,
                  label: 'Island Shot',
                  color: _ctrl.islandBackgroundColor,
                  enabled: _ctrl.currentTeam.canIslandShot &&
                      _ctrl.currentTeam.cups
                          .any((c) => c.isVisible && _ctrl.isIslandCup(c)),
                  onTap: _highlightIslandCups,
                ),
              _buildSheetAction(
                ctx: ctx,
                icon: Icons.sports_tennis_rounded,
                label: 'Bounce Shot',
                color: Colors.orange,
                onTap: _handleBounceShot,
              ),
              _buildSheetAction(
                ctx: ctx,
                icon: Icons.workspaces_outlined,
                label: 'Rearrange Cups',
                color: Colors.green,
                onTap: () => _ctrl.toggleRearranged(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetAction({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final effectiveColor = enabled ? color : Colors.grey;
    return ListTile(
      enabled: enabled,
      onTap: enabled
          ? () {
              Navigator.pop(ctx);
              onTap();
            }
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: effectiveColor.withValues(alpha: 0.15),
        child: Icon(icon, color: effectiveColor, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ----- Water Splash Animation (kept for potential reuse) -----

class WaterSplashAnimation extends StatefulWidget {
  final Color splashColor;
  const WaterSplashAnimation({super.key, this.splashColor = Colors.blue});

  @override
  State<WaterSplashAnimation> createState() => _WaterSplashAnimationState();
}

class _WaterSplashAnimationState extends State<WaterSplashAnimation> {
  final List<_WaterSplash> _splashes = [];
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
    if (_splashes.length >= 20) return;
    final splash = _WaterSplash(
      x: (timer.tick % 100) / 100.0,
      y: (timer.tick % 50) / 50.0,
    );
    setState(() => _splashes.add(splash));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashes.remove(splash));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _splashes
          .map((splash) => Positioned(
                left: splash.x * MediaQuery.of(context).size.width,
                top: splash.y * MediaQuery.of(context).size.height,
                child: TweenAnimationBuilder(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 1.0, end: 0.0),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Container(
                      width: 50 * value,
                      height: 50 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.splashColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _WaterSplash {
  final double x, y;
  _WaterSplash({required this.x, required this.y});
}
