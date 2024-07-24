import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

void main() {
  test('Team clone', () {
    final team = Team(
      color: Colors.blue,
      players: [Player(name: 'John'), Player(name: 'Doe')],
      cups: [Cup(index: 1), Cup(index: 2)],
    );
    final clone = team.clone();

    expect(clone.color, team.color);
    expect(clone.players.length, team.players.length);
    expect(clone.cups.length, team.cups.length);
    expect(clone.isRearranged, team.isRearranged);
    expect(clone.canIslandShot, team.canIslandShot);
  });

  test('Team rotatePlayers', () {
    final team = Team(
      color: Colors.red,
      players: [Player(name: 'John'), Player(name: 'Doe'), Player(name: 'Alice')],
      cups: [Cup(index: 1), Cup(index: 2)],
    );

    final rotatedPlayers = team.rotatePlayers();
    expect(rotatedPlayers.length, 2);
    expect(rotatedPlayers[0].name, 'Doe');
    expect(rotatedPlayers[1].name, 'Alice');
  });

  test('Team ballsBack', () {
    final team = Team(
      color: Colors.green,
      players: [Player(name: 'John', hitThisRound: 1), Player(name: 'Doe', hitThisRound: 1)],
      cups: [Cup(index: 1), Cup(index: 2)],
    );

    expect(team.ballsBack(), true);
  });
}
