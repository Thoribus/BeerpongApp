import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/event.dart';

void main() {
  group('GameEvent', () {
    test('fromJson constructs correctly with all fields', () {
      // timestamp is null here — fromJson falls back to DateTime.now()
      final json = <String, dynamic>{
        'eventType': 'Hit',
        'team': 'Team Blue',
        'player': 'player123',
        'timestamp': null,
      };

      final event = GameEvent.fromJson(json, 'evt1', 'game1');

      expect(event.eventId, 'evt1');
      expect(event.gameId, 'game1');
      expect(event.eventType, 'Hit');
      expect(event.team, 'Team Blue');
      expect(event.player, 'player123');
      // Null timestamp falls back to DateTime.now() — just verify it is not null
      expect(event.timestamp, isA<DateTime>());
    });

    test('fromJson handles null player gracefully', () {
      final json = <String, dynamic>{
        'eventType': 'Airball',
        'team': 'Team Red',
        'player': null,
        'timestamp': null,
      };

      final event = GameEvent.fromJson(json, 'evt2', 'game2');

      expect(event.player, isNull);
      expect(event.eventType, 'Airball');
    });

    test('toJson contains correct keys', () {
      final event = GameEvent(
        eventId: 'evt3',
        eventType: 'Miss',
        gameId: 'game3',
        player: 'p1',
        team: 'Team Blue',
        timestamp: DateTime(2024, 1, 1),
      );

      final json = event.toJson();

      expect(json.containsKey('eventType'), isTrue);
      expect(json.containsKey('team'), isTrue);
      expect(json.containsKey('player'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
      expect(json['eventType'], 'Miss');
      expect(json['team'], 'Team Blue');
      expect(json['player'], 'p1');
    });

    test('toJson with null player stores null for player key', () {
      final event = GameEvent(
        eventId: 'evt4',
        eventType: 'Bitchcup',
        gameId: 'game4',
        player: null,
        team: 'Team Red',
        timestamp: DateTime(2024, 6, 15),
      );

      final json = event.toJson();

      expect(json['player'], isNull);
    });

    test('toString produces expected format', () {
      final ts = DateTime(2024, 3, 10, 14, 30);
      final event = GameEvent(
        eventId: 'evt5',
        eventType: 'Island',
        gameId: 'game5',
        player: 'alice',
        team: 'Team Blue',
        timestamp: ts,
      );

      final result = event.toString();

      expect(result, contains('Island'));
      expect(result, contains('alice'));
      expect(result, contains('Team Blue'));
    });

    test('roundNumber is stored in toJson and read back in fromJson', () {
      final event = GameEvent(
        eventId: 'evt7',
        eventType: 'Normal Hit',
        gameId: 'game7',
        player: 'alice',
        team: 'Team Blue',
        timestamp: DateTime(2024, 1, 1),
        roundNumber: 3,
      );

      final json = event.toJson();
      expect(json['roundNumber'], 3);

      final restored = GameEvent.fromJson({...json, 'timestamp': null}, 'evt7', 'game7');
      expect(restored.roundNumber, 3);
    });

    test('roundNumber is omitted from toJson when null', () {
      final event = GameEvent(
        eventId: 'evt8',
        eventType: 'Airball',
        gameId: 'game8',
        player: null,
        team: 'Team Red',
        timestamp: DateTime(2024, 1, 1),
      );

      final json = event.toJson();
      expect(json.containsKey('roundNumber'), isFalse);
    });

    test('fromJson with missing roundNumber defaults to null', () {
      final json = <String, dynamic>{
        'eventType': 'Hit',
        'team': 'Team Blue',
        'player': null,
        'timestamp': null,
      };
      final event = GameEvent.fromJson(json, 'evt9', 'game9');
      expect(event.roundNumber, isNull);
    });

    test('toString handles null player', () {
      final event = GameEvent(
        eventId: 'evt6',
        eventType: 'Rebuttal',
        gameId: 'game6',
        player: null,
        team: 'Team Red',
        timestamp: DateTime(2024, 1, 1),
      );

      final result = event.toString();

      expect(result, contains('null'));
      expect(result, contains('Rebuttal'));
    });
  });
}
