import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/route_args.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TournamentOverviewScreen extends StatefulWidget {
  final String tournamentId;
  final Tournament tournament;
  final void Function(Tournament)? onTournamentUpdated;

  const TournamentOverviewScreen({
    super.key,
    required this.tournamentId,
    required this.tournament,
    this.onTournamentUpdated,
  });

  @override
  State<TournamentOverviewScreen> createState() =>
      _TournamentOverviewScreenState();
}

class _TournamentOverviewScreenState extends State<TournamentOverviewScreen> {
  late Tournament tournament;
  late final PageController _matchPageController;

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
    _matchPageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _matchPageController.dispose();
    super.dispose();
  }

  Future<void> _reloadTournamentData() async {
    final latest = await FirestoreService.instance.getTournament(widget.tournamentId);
    if (latest != null) {
      setState(() {
        tournament = latest;
      });
      _checkIfTournamentComplete();
      widget.onTournamentUpdated?.call(latest);
    }
  }

  Future<String?> _showStartingTeamDialog({
    required BuildContext context,
    required List<Player> team1Players,
    required List<Player> team2Players,
  }) async {
    const team1Name = 'Team Blue';
    const team2Name = 'Team Red';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(context.loc.gameModeWhoStarts),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamDialogColumn(team1Name, team1Players, Colors.blue),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(context.loc.labelVs,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _buildTeamDialogColumn(team2Name, team2Players, Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.loc.gameModeWhichTeamStarts),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(team1Name),
              child: Text(context.loc.gameModeTeamStarts(team1Name),
                  style: const TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(team2Name),
              child: Text(context.loc.gameModeTeamStarts(team2Name),
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamDialogColumn(
      String name, List<Player> players, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(name,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ...players.map((n) => Text(n.name)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTeamsSection(),
                const SizedBox(height: 24),
                _buildMatchesHeader(),
              ]),
            ),
          ),
          _buildMatchesSection(),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.labelTeams,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tournament.teams.length,
            itemBuilder: (context, index) {
              final team = tournament.teams[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showTeamTooltip(context, team);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: team.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            team.players
                                .map((p) => p.name.substring(0, 1))
                                .join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTeamTooltip(BuildContext context, Team team) {
    // Use a delayed post-frame callback to ensure the widget is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject();
      if (renderBox == null || renderBox is! RenderBox) return;

      final overlay = Overlay.of(context);
      final button = renderBox;

      final position = button.localToGlobal(
        Offset(button.size.width / 2, button.size.height),
        ancestor: overlay.context.findRenderObject(),
      );

      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (context) => Positioned(
          left: position.dx - 60,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.players.map((p) => p.name).join(' & '),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${team.wins}W - ${team.losses}L',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 2), () {
        entry?.remove();
      });
    });
  }

  Widget _buildMatchesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Matches",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'See all',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final match = tournament.matches[index];
            return _buildMatchCard(match, index);
          },
          childCount: tournament.matches.length,
        ),
      ),
    );
  }

  Widget _buildMatchCard(TournamentMatch match, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Match',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamColumn(match.team1, true),
                    const Column(
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '14:00', // Replace with actual time if available
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    _buildTeamColumn(match.team2, false),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.played
                      ? match.winner != null
                          ? 'Winner: ${match.winner!.players.map((p) => p.name).join(', ')}'
                          : 'Draw'
                      : 'Not played yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: match.played ? Colors.green[700] : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!match.played)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _startMatch(index),
                    child: const Text(
                      'Start Match',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(Team team, bool isLeft) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: team.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              team.players.map((p) => p.name.substring(0, 1)).join(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            team.players.map((p) => p.name).join(' & '),
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _startMatch(int index) async {
    var match = tournament.matches[index];
    final chosenTeam = await _showStartingTeamDialog(
      context: context,
      team1Players: match.team1.players,
      team2Players: match.team2.players,
    );
    if (chosenTeam == null) return;
    if (!mounted) return;

    // 1. Create the Firestore document for the game.
    final gameId = await FirestoreService.instance.createEmptyGameDoc(
      team1: match.team1,
      team2: match.team2,
    );
    await FirestoreService.instance.updateGameDoc(
      gameId,
      rules: match.selectedRules.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      startingTeam: chosenTeam,
      invitations: match.invitations,
      started: true,
      timestamp: true,
      tournamentId: tournament.id,
    );
    if (!mounted) return;

    // 2. (Optional) Save gameId to the TournamentMatch and update the tournament doc in Firestore.
    // If your TournamentMatch has a gameId field, do:
    match = match.copyWith(id: gameId);
    final cleanTeam1Players =
        match.team1.players.map((p) => p.copyWithResetStats()).toList();
    final team1 = Team(
        color: match.team1.color,
        players: cleanTeam1Players,
        cups: match.team1.cups);
    final cleanTeam2Players =
        match.team2.players.map((p) => p.copyWithResetStats()).toList();
    final team2 = Team(
        color: match.team2.color,
        players: cleanTeam2Players,
        cups: match.team2.cups);

    final result = await context.push<Map<String, dynamic>>(
      '/game',
      extra: GameArgs(
        id: gameId,
        team1: team1,
        team2: team2,
        selectedRules: match.selectedRules,
        invitations: match.invitations,
        startingTeam: chosenTeam == 'Team Blue',
        tournamentId: widget.tournamentId,
      ),
    );
    if (!mounted) return;

    if (result != null) {
      tournament.matches[index] = result['match'];
      mergeMatchResultsIntoTournament(
        tournamentTeams: tournament.teams,
        matchTeams: [result['match'].team1, result['match'].team2],
      );
      await FirestoreService.instance.updateTournament(tournament);
      await _reloadTournamentData();
    }
  }

  void _checkIfTournamentComplete() {
    if (tournament.matches.every((m) => m.played)) {
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.loc.tournamentCompleteTitle),
            content: Text(context.loc.tournamentCompleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(context.loc.btnOk),
              ),
            ],
          ),
        );
      });
    }
  }

  List<Player> mergePlayerStats(
      List<Player> tournamentPlayers, List<Player> matchPlayers) {
    final matchMap = {for (var p in matchPlayers) p.name: p};
    return tournamentPlayers.map((tp) {
      final match = matchMap[tp.name];
      return match != null ? tp.mergedWith(match) : tp;
    }).toList();
  }

  void mergeMatchResultsIntoTournament({
    required List<Team> tournamentTeams,
    required List<Team> matchTeams,
  }) {
    final matchTeamMap = {for (var t in matchTeams) t.color: t};
    for (int i = 0; i < tournamentTeams.length; i++) {
      final tournamentTeam = tournamentTeams[i];
      final matchTeam = matchTeamMap[tournamentTeam.color];
      if (matchTeam != null) {
        tournamentTeams[i] = tournamentTeam.copyWith(
          players: mergePlayerStats(tournamentTeam.players, matchTeam.players),
          wins: tournamentTeam.wins + matchTeam.wins,
          losses: tournamentTeam.losses + matchTeam.losses,
        );
      }
    }
  }
}
