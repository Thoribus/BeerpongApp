// lib/screens/game/live_game_stats_screen.dart

import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LiveGameStatsScreen extends StatefulWidget {
  final String gameId;

  const LiveGameStatsScreen({super.key, required this.gameId});

  @override
  LiveGameStatsScreenState createState() => LiveGameStatsScreenState();
}

class LiveGameStatsScreenState extends State<LiveGameStatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Game Stats'),
        backgroundColor: AppConstants.primaryColor,
      ),
      backgroundColor: Colors.black,
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

          final winnerField = gameData['winner'];
          if (winnerField != null && winnerField is String && winnerField.isNotEmpty) {
            List<Player> winningPlayers = [];
              if (winnerField == "Team Blue") {
                winningPlayers = team1.players;
              } else if (winnerField == "Team Red") {
                winningPlayers = team2.players;
              } else {
                print('Invalid winner field: $winnerField');
              }

              // Show the game end dialog
              WidgetsBinding.instance.addPostFrameCallback((_) {
                DialogHelpers.showGameEndDialog(context, winningPlayers);
              });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBracket(team1, team2),
                const SizedBox(height: 20),
                _buildCupLayouts(team1, team2),
                _buildTeamStats('Team Blue', team1.players, team1.color),
                const SizedBox(height: 20),
                _buildTeamStats('Team Red', team2.players, team2.color),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Displays both CupLayout widgets next to each other and scaled to fit the screen width
  /// Displays both CupLayout widgets next to each other and rotated by 90 degrees
  Widget _buildCupLayouts(Team team1, Team team2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Calculate scale factor based on screen width
        final scaleFactor =
            screenWidth / (screenWidth * 0.8); // Adjust this factor as needed

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Apply scaling and rotation to the first cup layout
              Transform.rotate(
                angle:
                    -90 * 3.14159 / 180, // Rotate 90 degrees counterclockwise
                child: Transform.scale(
                  scale: scaleFactor * 0.4,
                  child: CupLayout.buildCupsArea(team: team1),
                ),
              ),
              const SizedBox(width: 10), // Space between the two cup layouts
              // Apply scaling and rotation to the second cup layout
              Transform.rotate(
                angle: 90 * 3.14159 / 180, // Rotate 90 degrees clockwise
                child: Transform.scale(
                  scale: scaleFactor * 0.4,
                  child: CupLayout.buildCupsArea(team: team2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the top bracket with rounded corners, background image (SVG), and team avatars
  Widget _buildBracket(Team team1, Team team2) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          // SVG Background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/liquid-cheese.svg', // Path to your SVG
              fit: BoxFit.cover,
            ),
          ),
          // Content on top of the SVG
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTeamAvatar(team1),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildTeamAvatar(team2),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${team1.players[0].score} - ${team2.players[0].score}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a round avatar for each team
  Widget _buildTeamAvatar(Team team) {
    return CircleAvatar(
      child: ClipOval(
        child: SvgPicture.asset(
          'assets/avatars/avatar_catbeer.svg',
          fit: BoxFit.cover,
          width: 45,
          height: 45,
        ),
      ), // Replace with your team avatar URL
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
