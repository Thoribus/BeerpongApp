import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:go_router/go_router.dart';

class ReadOnlyLobbyScreen extends StatelessWidget {
  final String gameId;

  const ReadOnlyLobbyScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    // Listen to the game doc
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: const Text('Lobby - Error')),
            body: const Center(
              child: Text('Error loading game.',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(title: const Text('Lobby')),
            body: const Center(
              child: Text('Loading game...',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        // If the game has started => go to LiveGameStatsScreen
        final started = data['started'] == true;
        if (started) {
          // Navigate to LiveGameStatsScreen
          // Because this is in a build method, do a post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.pushReplacement('/spectate-live/$gameId');
          });
        }

        // Otherwise, parse the teams to display in read-only format
        final team1Json = data['team1'] ?? {};
        final team2Json = data['team2'] ?? {};

        final team1 = Team.fromJson(team1Json);
        final team2 = Team.fromJson(team2Json);

        final gameMode = data['gameMode'] ?? 'Unknown Mode';
        final rulesList = (data['specialRules'] as List?) ?? [];
        final startingTeam = data['startingTeam'] ?? 'Team Blue';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Lobby - Read Only'),
            backgroundColor: Colors.amber,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTeamPanel('Team Blue', team1, Colors.blue),
                const SizedBox(height: 16),
                _buildTeamPanel('Team Red', team2, Colors.red),
                const SizedBox(height: 16),
                _buildGameSettings(gameMode, rulesList, startingTeam),
                const SizedBox(height: 16),
                const Text(
                  'Waiting for the host to start the game...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamPanel(String title, Team team, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Column(
            children: team.players.map((player) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  player.name,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSettings(String mode, List rules, String starting) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Game Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber)),
          const SizedBox(height: 8),
          Text('Game Mode: $mode', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Special Rules: ${rules.join(', ')}',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Starting Team: $starting',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
