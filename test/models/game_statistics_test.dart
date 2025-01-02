import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('GameStatistics fromFirestore', () {
    final data = {
      'timestamp': Timestamp.fromDate(DateTime(2023, 1, 1)),
      'winner': 'Team 1',
      'team1': [
        {
          'name': 'John',
          'score': 10.0,
          'throws': 15,
          'misses': 5,
          'airballs': 2,
          'hitThisRound': 1,
          'cupsHit': [1, 2, 3],
          'lastCupHit': false,
          'islandShotUsed': false,
          'defended': 1,
          'consecuteiveHits': 3,
          'onFire': 1,
        }
      ],
      'team2': [
        {
          'name': 'Doe',
          'score': 5.0,
          'throws': 10,
          'misses': 3,
          'airballs': 1,
          'hitThisRound': 0,
          'cupsHit': [1],
          'lastCupHit': false,
          'islandShotUsed': false,
          'defended': 0,
          'consecuteiveHits': 1,
          'onFire': 0,
        }
      ],
      'participants': ['John', 'Doe']
    };

    final stats = GameStatistics.fromFirestore(data);

    expect(stats.date, DateTime(2023, 1, 1));
    expect(stats.winningTeam, 'Team 1');
    expect(stats.team1Players.length, 1);
    expect(stats.team2Players.length, 1);
    expect(stats.participants.length, 2);
  });
}
