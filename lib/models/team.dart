import 'package:flutter/material.dart';
import 'cup.dart';
import 'player.dart';

class Team {
  final Color color; 
  List<Player> players;
  List<Player> currentPlayers = [];
  List<Cup> cups;
  bool isRearranged = false;
  bool canIslandShot = true;

  Team({
    required this.color,
    required this.players,
    required this.cups,
    this.currentPlayers = const [],
    this.isRearranged = false,
    this.canIslandShot = true,
  });

  List<Player> rotatePlayers() {
    if (players.length <= 2) return players;

    Player player1 = players.removeAt(0);
    Player player2 = players.removeAt(0);
    players.add(player1);
    players.add(player2);

    return players.sublist(0, 2);
  }

  bool ballsBack() {
    return currentPlayers.map((player) => player.hitThisRound).reduce((a, b) => a + b) == 2;
  }

  @override
  String toString() {
    return 'Team(color: $color, players: $players, cups: $cups, currentPlayers: $currentPlayers, isRearranged: $isRearranged, canIslandShot: $canIslandShot)';
  }

  Team clone() {
    return Team(
      color: color,
      players: players.map((player) => player.clone()).toList(),
      cups: cups.map((cup) => cup.clone()).toList(),
      currentPlayers: currentPlayers.map((player) => player.clone()).toList(),
      isRearranged: isRearranged,
      canIslandShot: canIslandShot,
    );
  }
}