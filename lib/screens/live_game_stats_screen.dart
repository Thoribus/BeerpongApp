// lib/screens/game/live_game_stats_screen.dart

import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/constants.dart';

class LiveGameStatsScreen extends StatefulWidget {
  final String gameId;

  const LiveGameStatsScreen({super.key, required this.gameId});

  @override
  _LiveGameStatsScreenState createState() => _LiveGameStatsScreenState();
}

class _LiveGameStatsScreenState extends State<LiveGameStatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Game Stats'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getGameDocStream(widget.gameId),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Game not found.',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          // Extract game data
          final gameData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          Team team1 = Team.fromJson(gameData['team1']);
          Team team2 = Team.fromJson(gameData['team2']);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CupLayout.buildCupsArea(team: team1),
                _buildTeamStats('Team Blue', team1.players, team1.color),
                const SizedBox(height: 20),
                CupLayout.buildCupsArea(team: team2),
                _buildTeamStats('Team Red', team2.players, team2.color),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the stats section for a team
  Widget _buildTeamStats(
      String teamName, List<Player> players, Color teamColor) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: teamColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white),
            Expanded(
              child: players.isEmpty
                  ? const Text('No players in this team.',
                      style: TextStyle(color: Colors.white))
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return _buildPlayerStat(player);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the stat row for a single player
  Widget _buildPlayerStat(Player player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppConstants.secondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Text(
            'Score: ${player.score}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
