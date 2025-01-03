import 'package:flutter/material.dart';
import 'cup.dart';
import 'player.dart';

class Team {
  final Color color;
  List<Player> players;
  List<Player> currentPlayers;
  List<Cup> cups;
  bool isRearranged;
  bool canIslandShot;

  Team({
    required this.color,
    required this.players,
    required this.cups,
    this.currentPlayers = const [],
    this.isRearranged = false,
    this.canIslandShot = true,
  });

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

  bool ballsBack() {
    return currentPlayers.fold<int>(0, (sum, p) => sum + p.hitThisRound) == 2;
  }

  /// Convert this Team instance into a JSON-friendly map.
  Map<String, dynamic> toJson() {
    return {
      'colorValue': color.value,                // store color as int
      'players': Player.encodeList(players),    // store players in JSON
      'cups': Cup.encodeList(cups),            // store cups in JSON
      'isRearranged': isRearranged,
      'canIslandShot': canIslandShot,
    };
  }

  /// Recreate a Team from a JSON map.
  factory Team.fromJson(Map<String, dynamic> data) {
    final colorValue = data['colorValue'] as int? ?? Colors.blue.value;
    return Team(
      color: Color(colorValue),
      players: Player.decodeList(data['players'] as String),
      cups: Cup.decodeList(data['cups'] as String),
      isRearranged: data['isRearranged'] as bool? ?? false,
      canIslandShot: data['canIslandShot'] as bool? ?? true,
      // currentPlayers is ephemeral; typically rebuilt via rotatePlayers().
      // but you could store it if you want to preserve exact rotation
    );
  }

  Team clone() {
    return Team(
      color: color,
      players: players.map((p) => p.clone()).toList(),
      cups: cups.map((c) => c.clone()).toList(),
      currentPlayers: currentPlayers.map((p) => p.clone()).toList(),
      isRearranged: isRearranged,
      canIslandShot: canIslandShot,
    );
  }

  @override
  String toString() {
    return 'Team(color: $color, players: $players, cups: $cups, '
        'currentPlayers: $currentPlayers, isRearranged: $isRearranged, '
        'canIslandShot: $canIslandShot)';
  }
}
