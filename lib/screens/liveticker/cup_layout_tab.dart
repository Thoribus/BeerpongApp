import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';

class CupLayoutTab extends StatelessWidget {
  final LiveGameData gameData;
  const CupLayoutTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Team Stat Brackets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamStatBracket(gameData.team1, isLeft: true),
              _buildTeamStatBracket(gameData.team2, isLeft: false),
            ],
          ),

          const SizedBox(height: 16),

          // Placeholder for Cup Layouts Row
          _buildCupLayoutsRow(gameData.team1, gameData.team2),

          const SizedBox(height: 16),

          // Player Tables Beneath Cup Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerTable(gameData.team1, isLeft: true),
              _buildPlayerTable(gameData.team2, isLeft: false, mirrored: true),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTeamStatBracket(Team team, {required bool isLeft}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLeft
                ? [Colors.blue.shade700, Colors.grey]
                : [Colors.grey, Colors.red.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: team.players.map((player) {
            return Expanded(
              child: Column(
                children: [
                  player.user == null
                      ? const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 8,
                          ),
                        )
                      : CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white24,
                          child: ClipOval(
                            child: SvgPicture.asset(
                              player.user!.mapAvatarKeyToAsset(),
                              fit: BoxFit.cover,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    player.name.length > 10
                        ? "${player.name.substring(0, 9)}…"
                        : player.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPlayerTable(Team team,
      {required bool isLeft, bool mirrored = false}) {
    return Column(
      children: team.players.map((player) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isLeft ? Colors.blue.shade700 : Colors.red.shade700,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                player.user == null
                    ? const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 8,
                        ),
                      )
                    : CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white24,
                        child: ClipOval(
                          child: SvgPicture.asset(
                            player.user!.mapAvatarKeyToAsset(),
                            fit: BoxFit.cover,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                _buildStatBadge(player.cupsHit.length.toString(), "Cups Hit"),
                _buildStatBadge(player.airballs.toString(), "Airballs"),
                _buildStatBadge(player.throws.toString(), "Throws"),
                _buildStatBadge(player.misses.toString(), "Misses"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatBadge(String statValue, String statName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statValue,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statName,
          style: const TextStyle(fontSize: 8, color: Colors.white70),
        ),
      ],
    );
  }

  /// Placeholder for your actual cup layouts (center content)
  Widget _buildCupLayoutsRow(Team team1, Team team2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: SizedBox(
        height: 200,
        width: double.infinity, // 👈 Bounded width to prevent Stack overflow
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.2),
                Colors.grey.shade600,
                Colors.amber.withOpacity(0.2)
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            children: [
              // Left Cup Layout
              Positioned(
                right: 160,
                top: 10,
                bottom: 10,
                child: Transform.rotate(
                  angle: -90 * 3.14159 / 180,
                  child: Transform.scale(
                    scale: 0.5,
                    child: CupLayout.buildCupsArea(team: team1),
                  ),
                ),
              ),
              // Right Cup Layout
              Positioned(
                left: 160,
                top: 10,
                bottom: 10,
                child: Transform.rotate(
                  angle: 90 * 3.14159 / 180,
                  child: Transform.scale(
                    scale: 0.5,
                    child: CupLayout.buildCupsArea(team: team2),
                  ),
                ),
              ),
              // Divider
              Center(
                child: Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
