// lib/screens/game/live_game_stats_screen.dart

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
          final gameData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Parse team1 and team2 players
          List<Player> team1Players = [];
          List<Player> team2Players = [];

          if (gameData['team1'] != null) {
            team1Players = List<Map<String, dynamic>>.from(gameData['team1'])
                .map((playerData) => Player.fromJson(playerData))
                .toList();
          }

          if (gameData['team2'] != null) {
            team2Players = List<Map<String, dynamic>>.from(gameData['team2'])
                .map((playerData) => Player.fromJson(playerData))
                .toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTeamStats('Team Blue', team1Players, Colors.blue),
                const SizedBox(height: 20),
                _buildTeamStats('Team Red', team2Players, Colors.red),
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
