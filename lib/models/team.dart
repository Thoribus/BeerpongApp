import 'package:flutter/material.dart';
import 'cup.dart';
import 'player.dart';

/// A class representing a team in the game.
class Team {
  final Color color;              // Team color (blue, red, etc.)
  List<Player> players;           // All players on this team
  List<Player> currentPlayers;    // The two players currently playing
  List<Cup> cups;                 // The cups belonging to this team
  bool isRearranged;              // Whether cups have been rearranged
  bool canIslandShot;             // Whether island shot is allowed

  Team({
    required this.color,
    required this.players,
    required this.cups,
    this.currentPlayers = const [],
    this.isRearranged = false,
    this.canIslandShot = true,
  });

  /// Rotates players for 2v2 logic. If the list is bigger than 2, rotates them.
  List<Player> rotatePlayers() {
    if (players.length <= 2) {
      currentPlayers = players;
      return currentPlayers;
    }

    final player1 = players.removeAt(0);
    final player2 = players.removeAt(0);
    players.add(player1);
    players.add(player2);

    currentPlayers = players.sublist(0, 2);
    return currentPlayers;
  }

  /// Checks if the entire currentPlayers team got 2 hits (Balls Back).
  bool ballsBack() {
    // sum of hitThisRound for the two active players
    return currentPlayers.fold<int>(0, (sum, p) => sum + p.hitThisRound) == 2;
  }

  /// Clones this Team instance deeply.
  Team clone() {
    return Team(
      color: color,
      players: players.map((p) => p.clone()).toList(),
      cups: cups.map((cup) => cup.clone()).toList(),
      currentPlayers: currentPlayers.map((p) => p.clone()).toList(),
      isRearranged: isRearranged,
      canIslandShot: canIslandShot,
    );
  }

  @override
  String toString() {
    return 'Team(color: $color, players: $players, cups: $cups, currentPlayers: $currentPlayers, isRearranged: $isRearranged, canIslandShot: $canIslandShot)';
  }
}
