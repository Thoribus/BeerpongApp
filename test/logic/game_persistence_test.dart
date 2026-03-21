import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Team _team(Color color, String playerName) {
  return Team(
    color: color,
    players: [Player(name: playerName)],
    cups: List.generate(3, (i) => Cup(index: i, color: color)),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GamePersistence', () {
    test('saveGameState + loadGameState round-trip keeps key fields', () async {
      final team1 = _team(Colors.blue, 'Blue Player');
      final team2 = _team(Colors.red, 'Red Player');

      await GamePersistence.saveGameState(
        id: 'game-abc',
        team1: team1,
        team2: team2,
        isTeamOneTurn: false,
        islandShotActive: true,
        invitations: const ['inv-1', 'inv-2'],
        selectedRules: const {'Island': true, 'Putback': false},
        tournamentId: 'tour-77',
      );

      final loaded = await GamePersistence.loadGameState();
      expect(loaded, isNotNull);
      expect(loaded!['id'], 'game-abc');
      expect(loaded['isTeamOneTurn'], isFalse);
      expect(loaded['islandShotActive'], isTrue);
      expect(loaded['tournamentId'], 'tour-77');
      expect(loaded['invitations'], ['inv-1', 'inv-2']);
      expect((loaded['selectedRules'] as Map)['Island'], isTrue);
      expect((loaded['team1'] as Map)['players'][0]['name'], 'Blue Player');
      expect((loaded['team2'] as Map)['players'][0]['name'], 'Red Player');
    });

    test('loadGameState returns null when no state exists', () async {
      final loaded = await GamePersistence.loadGameState();
      expect(loaded, isNull);
    });

    test('clearGameState(false) removes only local persisted state', () async {
      await GamePersistence.saveGameState(
        id: 'game-clear-test',
        team1: _team(Colors.blue, 'A'),
        team2: _team(Colors.red, 'B'),
        isTeamOneTurn: true,
        islandShotActive: false,
        invitations: const [],
        selectedRules: const {'Island': false},
        tournamentId: '',
      );
      final prefsBefore = await SharedPreferences.getInstance();
      expect(prefsBefore.getString(AppConstants.prefGameState), isNotNull);

      await GamePersistence.clearGameState(false);

      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getString(AppConstants.prefGameState), isNull);
    });

    test('clearGameState(false) is a no-op when nothing is stored', () async {
      await GamePersistence.clearGameState(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefGameState), isNull);
    });
  });
}
