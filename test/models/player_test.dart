import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';

void main() {
  test('Player toJson and fromJson', () {
    final player = Player(
      name: 'John',
      score: 10,
      throws: 15,
      misses: 5,
      airballs: 2,
      cupsHit: [1, 2, 3],
      hitThisRound: 1,
      islandShotUsed: false,
      defended: 1,
      consecutiveHits: 3,
      onFire: 1,
      user: User(id: '123', username: 'john_doe'),
    );
    final json = player.toJson();
    final newPlayer = Player.fromJson(json);

    expect(newPlayer.name, player.name);
    expect(newPlayer.score, player.score);
    expect(newPlayer.throws, player.throws);
    expect(newPlayer.misses, player.misses);
    expect(newPlayer.airballs, player.airballs);
    expect(newPlayer.cupsHit, player.cupsHit);
    expect(newPlayer.hitThisRound, player.hitThisRound);
    expect(newPlayer.islandShotUsed, player.islandShotUsed);
    expect(newPlayer.defended, player.defended);
    expect(newPlayer.consecutiveHits, player.consecutiveHits);
    expect(newPlayer.onFire, player.onFire);
    expect(newPlayer.user?.id, player.user?.id);
  });

  test('Player clone', () {
    final player = Player(name: 'John');
    final clone = player.clone();

    expect(clone.name, player.name);
    expect(clone.score, player.score);
  });

  test('Player encodeList and decodeList', () {
    final players = [
      Player(name: 'John'),
      Player(name: 'Doe'),
    ];
    final jsonString = Player.encodeList(players);
    final decodedPlayers = Player.decodeList(jsonString);

    expect(decodedPlayers.length, players.length);
    expect(decodedPlayers[0].name, players[0].name);
    expect(decodedPlayers[1].name, players[1].name);
  });
}
