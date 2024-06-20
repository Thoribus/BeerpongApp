import 'package:flutter/material.dart';
import 'cup.dart';
import 'player.dart';

class Team {
  final Color color; 
  List<Player> players;
  List<Player> currentPlayers = [];
  List<Cup> cups;
  List<Cup> remainingCups;
  bool isRearranged = false;
  bool canIslandShot = true;

  Team({
    required this.color,
    required this.players,
    required this.cups,
    this.currentPlayers = const [],
    this.remainingCups = const [],
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

  @override
  String toString() {
    return 'Team: ${players.map((player) => player.name).join(', ')}';
  }
}