import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import '../game/game_screen.dart';

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
    final latest = await FirestoreService().getTournament(widget.tournamentId);
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
    const team1Name = "Team Blue";
    const team2Name = "Team Red";

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
                  _buildTeamDialogColumn(team1Name, team1Players, Colors.blue),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('VS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _buildTeamDialogColumn(team2Name, team2Players, Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Which team should start?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(team1Name),
              child: Text('$team1Name starts',
                  style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(team2Name),
              child: Text('$team2Name starts',
                  style: TextStyle(color: Colors.red)),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Teams",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTeamsSection(),
            const SizedBox(height: 24),
            const Text("Matches",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: _buildMatchesSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Teams",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: tournament.teams.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two columns
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.5, // Adjust height vs width
                  ),
                  itemBuilder: (context, index) {
                    final team = tournament.teams[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: team.color.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: team.color,
                              child: const Icon(Icons.group,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team.players.map((p) => p.name).join(', '),
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildMatchesSection() {
    return ListView.separated(
      itemCount: tournament.matches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        var match = tournament.matches[index];
        final team1 = match.team1.players.first;
        final team2 = match.team2.players.first;

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Single Game",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerColumn(team1.name, match.team1.color),
                    const Text("VS",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildPlayerColumn(team2.name, match.team2.color),
                  ],
                ),
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.played
                          ? match.winner != null
                              ? 'Winner: ${match.winner!.players.map((p) => p.name).join(', ')}'
                              : 'No winner recorded'
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
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          final chosenTeam = await _showStartingTeamDialog(
                            context: context,
                            team1Players: match.team1.players,
                            team2Players: match.team2.players,
                          );
                          if (chosenTeam == null) return;

                          final gameId =
                              await FirestoreService().createEmptyGameDoc(
                            team1: match.team1,
                            team2: match.team2,
                          );

                          await FirestoreService().updateGameDoc(
                            gameId,
                            rules: match.selectedRules.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList(),
                            startingTeam: chosenTeam,
                            invitations: match.invitations,
                            started: true,
                            timestamp: true,
                            tournamendId: tournament.id,
                          );

                          match = match.copyWith(id: gameId);
                          final cleanTeam1 = Team(
                            color: match.team1.color,
                            players: match.team1.players
                                .map((p) => p.copyWithResetStats())
                                .toList(),
                            cups: match.team1.cups,
                          );
                          final cleanTeam2 = Team(
                            color: match.team2.color,
                            players: match.team2.players
                                .map((p) => p.copyWithResetStats())
                                .toList(),
                            cups: match.team2.cups,
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameScreen(
                                id: gameId,
                                team1: cleanTeam1,
                                team2: cleanTeam2,
                                selectedRules: match.selectedRules,
                                invitations: match.invitations,
                                startingTeam: chosenTeam == "Team Blue",
                                tournamentId: widget.tournamentId,
                              ),
                            ),
                          );

                          if (result != null) {
                            tournament.matches[index] = result["match"];
                            final List<Team> matchTeams = [
                              result["match"].team1,
                              result["match"].team2,
                            ];
                            mergeMatchResultsIntoTournament(
                              tournamentTeams: tournament.teams,
                              matchTeams: matchTeams,
                            );
                            await FirestoreService()
                                .updateTournament(tournament);
                            await _reloadTournamentData();
                          }
                        },
                        child: const Text("Start Match"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerColumn(String name, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

    final gameId = await FirestoreService().createEmptyGameDoc(
      team1: match.team1,
      team2: match.team2,
    );
    await FirestoreService().updateGameDoc(
      gameId,
      rules: match.selectedRules.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      startingTeam: chosenTeam,
      invitations: match.invitations,
      started: true,
      timestamp: true,
      tournamendId: tournament.id,
    );

    match = match.copyWith(id: gameId);
    final team1 = Team(
      color: match.team1.color,
      players: match.team1.players.map((p) => p.copyWithResetStats()).toList(),
      cups: match.team1.cups,
    );
    final team2 = Team(
      color: match.team2.color,
      players: match.team2.players.map((p) => p.copyWithResetStats()).toList(),
      cups: match.team2.cups,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          id: gameId,
          team1: team1,
          team2: team2,
          selectedRules: match.selectedRules,
          invitations: match.invitations,
          startingTeam: chosenTeam == "Team Blue",
          tournamentId: widget.tournamentId,
        ),
      ),
    );

    if (result != null) {
      tournament.matches[index] = result["match"];
      mergeMatchResultsIntoTournament(
        tournamentTeams: tournament.teams,
        matchTeams: [result["match"].team1, result["match"].team2],
      );
      await FirestoreService().updateTournament(tournament);
      await _reloadTournamentData();
    }
  }

  void _checkIfTournamentComplete() {
    if (tournament.matches.every((m) => m.played)) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tournament Complete!"),
            content: const Text(
                "All matches have been played.\nCheck out the standings!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
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
