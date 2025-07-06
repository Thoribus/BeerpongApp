import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import '../game/game_screen.dart'; // <-- Make sure this import is correct

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

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
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
    // Adjust team names if you want dynamic team names
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(team1Name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        ...team1Players.map((n) => Text(n.name)),
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
                        ...team2Players.map((n) => Text(n.name)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Teams",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: tournament.teams
                  .map((team) => Chip(
                        label: Text(team.players.map((p) => p.name).join(', ')),
                        backgroundColor: team.color.withOpacity(0.15),
                        avatar: CircleAvatar(
                          backgroundColor: team.color,
                          child: const Icon(Icons.group,
                              color: Colors.white, size: 16),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              "Matches",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: tournament.matches.length,
                separatorBuilder: (context, i) => const Divider(),
                itemBuilder: (context, index) {
                  var match = tournament.matches[index];
                  final team1 =
                      match.team1.players.map((p) => p.name).join(', ');
                  final team2 =
                      match.team2.players.map((p) => p.name).join(', ');
                  return ListTile(
                    title: Text('$team1 vs $team2'),
                    subtitle: match.played
                        ? Text(
                            match.winner != null
                                ? 'Winner: ${match.winner!.players.map((p) => p.name).join(', ')}'
                                : 'No winner recorded',
                            style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold),
                          )
                        : const Text('Not played yet'),
                    leading: Icon(
                      match.played
                          ? Icons.check_circle
                          : Icons.sports_esports_outlined,
                      color: match.played ? Colors.green : Colors.amber,
                    ),
                    trailing: match.played
                        ? null
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              String? chosenTeam =
                                  await _showStartingTeamDialog(
                                      context: context,
                                      team1Players: match.team1.players,
                                      team2Players: match.team2.players);
                              if (chosenTeam == null) return;

                              // 1. Create the Firestore document for the game.
                              final String gameId =
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

                              // 2. (Optional) Save gameId to the TournamentMatch and update the tournament doc in Firestore.
                              // If your TournamentMatch has a gameId field, do:
                              match = match.copyWith(id: gameId);
                              final cleanTeam1Players = match.team1.players
                                  .map((p) => p.copyWithResetStats())
                                  .toList();
                              final team1 = Team(color: match.team1.color, players: cleanTeam1Players, cups: match.team1.cups);
                              final cleanTeam2Players = match.team2.players
                                  .map((p) => p.copyWithResetStats())
                                  .toList();
                              final team2 = Team(color: match.team2.color, players: cleanTeam2Players, cups: match.team2.cups);

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
                                final List<Team> matchTeams = [
                                  result["match"].team1,
                                  result["match"].team2
                                ];
                                mergeMatchResultsIntoTournament(
                                    tournamentTeams: tournament.teams,
                                    matchTeams: matchTeams);
                                await FirestoreService()
                                    .updateTournament(tournament);
                                await _reloadTournamentData();
                              }
                            },
                            child: const Text("Start Match"),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Player> mergePlayerStats(
      List<Player> tournamentPlayers, List<Player> matchPlayers) {
    // Map for quick lookup
    final Map<String, Player> matchMap = {
      for (var p in matchPlayers) p.name: p
    };

    return tournamentPlayers.map((tp) {
      final match = matchMap[tp.name];
      return match != null ? tp.mergedWith(match) : tp;
    }).toList();
  }

  void mergeMatchResultsIntoTournament({
    required List<Team> tournamentTeams,
    required List<Team> matchTeams,
  }) {
    // Map matchTeams by color, or any unique property you use to identify teams!
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
      // else: leave untouched
    }
  }

  void _checkIfTournamentComplete() {
  if (tournament.matches.every((m) => m.played)) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Tournament Complete!"),
          content: const Text("All matches have been played.\nCheck out the standings!"),
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

}
