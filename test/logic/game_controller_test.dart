import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_controller.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Cup> _cups(Color color, {int count = 10}) {
  return List.generate(count, (i) => Cup(index: i, color: color));
}

Team _team(Color color, List<Player> players, {int cupCount = 10}) {
  return Team(
    color: color,
    players: players,
    cups: _cups(color, count: cupCount),
  );
}

Future<GameController> _loadController(
  WidgetTester tester, {
  required Team team1,
  required Team team2,
  bool startingTeam = true,
  Map<String, bool>? selectedRules,
  String id = 'game-1',
  List<String>? invitations,
  String tournamentId = '',
}) async {
  final ctrl = GameController(UserProvider());
  await ctrl.loadGameState(
    widgetId: id,
    widgetTeam1: team1,
    widgetTeam2: team2,
    widgetStartingTeam: startingTeam,
    widgetInvitations: invitations ?? const [],
    widgetSelectedRules: selectedRules ?? const {'Island': false},
    widgetTournamentId: tournamentId,
  );
  await tester.pump();
  return ctrl;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameController edge cases', () {
    testWidgets(
        'loadGameState restores persisted fields including tournamentId',
        (tester) async {
      final savedBlue = _team(
        Colors.blue,
        [Player(name: 'Saved Blue')],
        cupCount: 4,
      );
      final savedRed = _team(
        Colors.red,
        [Player(name: 'Saved Red')],
        cupCount: 4,
      );

      await GamePersistence.saveGameState(
        id: 'saved-game',
        team1: savedBlue,
        team2: savedRed,
        isTeamOneTurn: false,
        islandShotActive: true,
        invitations: const ['inv-1'],
        selectedRules: const {'Island': true, 'Putback': true},
        tournamentId: 'tournament-42',
      );

      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'Fallback Blue')]),
        team2: _team(Colors.red, [Player(name: 'Fallback Red')]),
        tournamentId: '',
      );

      expect(ctrl.id, 'saved-game');
      expect(ctrl.isTeamOneTurn, isFalse);
      expect(ctrl.islandShotActive, isTrue);
      expect(ctrl.tournamentId, 'tournament-42');
      expect(ctrl.currentTeam.color.toARGB32(), Colors.red.toARGB32());
      expect(ctrl.selectedRules['Putback'], isTrue);
      expect(ctrl.invitations, ['inv-1']);
      expect(ctrl.team1.players.first.name, 'Saved Blue');
      expect(ctrl.team2.players.first.name, 'Saved Red');
    });

    testWidgets(
        'endTurn updates misses/throws, hides green cups, and increments round every two turns',
        (tester) async {
      final team1 = _team(
        Colors.blue,
        [Player(name: 'A'), Player(name: 'B')],
        cupCount: 3,
      );
      final team2 = _team(
        Colors.red,
        [Player(name: 'C'), Player(name: 'D')],
        cupCount: 3,
      );
      final ctrl = await _loadController(
        tester,
        team1: team1,
        team2: team2,
        startingTeam: true,
      );

      final missPlayer = ctrl.currentTeam.currentPlayers[0];
      final hitPlayer = ctrl.currentTeam.currentPlayers[1];
      missPlayer.hitThisRound = 0;
      hitPlayer.hitThisRound = 1;
      ctrl.currentTeam.cups[0].color = Colors.green;

      ctrl.endTurn();
      await tester.pump();

      expect(missPlayer.misses, 1);
      expect(missPlayer.throws, 1);
      expect(missPlayer.hitThisRound, 0);
      expect(hitPlayer.misses, 0);
      expect(hitPlayer.throws, 0);
      expect(hitPlayer.hitThisRound, 0);
      expect(ctrl.team1.cups[0].isVisible, isFalse);
      expect(ctrl.isTeamOneTurn, isFalse);
      expect(ctrl.roundCount, 0);

      ctrl.endTurn();
      await tester.pump();
      expect(ctrl.isTeamOneTurn, isTrue);
      expect(ctrl.roundCount, 1);
    });

    testWidgets('endTurn — 1-player team with 0 hits gets 2 misses and 2 throws',
        (tester) async {
      final solo = Player(name: 'Solo');
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [solo], cupCount: 3),
        team2: _team(Colors.red, [Player(name: 'C')], cupCount: 3),
      );

      // solo player hits nothing this round
      solo.hitThisRound = 0;
      ctrl.endTurn();
      await tester.pump();

      expect(solo.misses, 2, reason: '1 player takes both throws; both missed');
      expect(solo.throws, 2);
      expect(solo.hitThisRound, 0);
    });

    testWidgets('endTurn — 1-player team with 1 hit gets 1 miss and 1 throw',
        (tester) async {
      final solo = Player(name: 'Solo');
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [solo], cupCount: 3),
        team2: _team(Colors.red, [Player(name: 'C')], cupCount: 3),
      );

      // The UI already called incrementPlayerThrows once for the hit.
      solo.throws = 1;
      solo.hitThisRound = 1;
      ctrl.endTurn();
      await tester.pump();

      expect(solo.misses, 1, reason: '1 player throws twice; 1 hit + 1 miss');
      expect(solo.throws, 2, reason: 'hit throw was pre-counted; endTurn adds the miss throw');
      expect(solo.hitThisRound, 0);
    });

    testWidgets('endTurn — 1-player balls-back bonus round all-miss gives 2 misses/throws',
        (tester) async {
      final solo = Player(name: 'Solo');
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [solo], cupCount: 3),
        team2: _team(Colors.red, [Player(name: 'C')], cupCount: 3),
      );

      // Simulate: original round both hit (tracked by UI), balls back fired
      // and reset hitThisRound to 0. Bonus round: both missed.
      solo.throws = 2; // already counted for the two original hits
      solo.hitThisRound = 0; // bonus round produced no hits

      ctrl.endTurn();
      await tester.pump();

      expect(solo.misses, 2, reason: 'bonus round: 2 throws, 0 hits → 2 misses');
      expect(solo.throws, 4, reason: '2 original hits + 2 bonus misses = 4 total throws');
    });

    testWidgets(
        'selectIslandShooter disables team island when the last player uses it',
        (tester) async {
      final first = Player(name: 'A');
      final second = Player(name: 'B')..islandAttempts = 1;
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [first, second], cupCount: 2),
        team2: _team(Colors.red, [Player(name: 'C')], cupCount: 2),
      );

      ctrl.selectIslandShooter(first);
      await tester.pump();

      expect(first.islandAttempts > 0, isTrue);
      expect(ctrl.currentIslandShooter, first);
      expect(ctrl.islandShotActive, isTrue);
      expect(ctrl.currentTeam.canIslandShot, isFalse);
      expect(ctrl.islandBackgroundColor, Colors.grey);
    });

    testWidgets('getRandomCupIndex throws when no eligible bonus cup exists',
        (tester) async {
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'A')], cupCount: 1),
        team2: _team(Colors.red, [Player(name: 'B')], cupCount: 1),
      );

      final onlyCup = ctrl.currentTeam.cups.first;
      expect(
        () => ctrl.getRandomCupIndex(
            [onlyCup], onlyCup.index, ctrl.currentTeam.color),
        throwsException,
      );
    });

    testWidgets('setGameEnded marks Team 1 winner and increments record',
        (tester) async {
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'A')], cupCount: 2),
        team2: _team(Colors.red, [Player(name: 'B')], cupCount: 2),
      );

      for (final cup in ctrl.team1.cups) {
        cup.color = Colors.green;
      }
      ctrl.setGameEnded();

      expect(ctrl.gameEnded, isTrue);
      expect(ctrl.winner, 'Team 1');
      expect(ctrl.cupsRemainingWinner, 0);
      expect(ctrl.team1.wins, 1);
      expect(ctrl.team2.losses, 1);
    });

    testWidgets('setGameEnded marks Team 2 winner and counts remaining cups',
        (tester) async {
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'A')], cupCount: 3),
        team2: _team(Colors.red, [Player(name: 'B')], cupCount: 3),
      );

      // Team 1 not fully cleared -> Team 2 should win.
      ctrl.team1.cups[0].isVisible = true;
      ctrl.team1.cups[0].color = Colors.blue;
      ctrl.team1.cups[1].color = Colors.green;
      ctrl.team1.cups[2].isVisible = false;

      // Team 2 has two cups remaining.
      ctrl.team2.cups[0].isVisible = true;
      ctrl.team2.cups[0].color = Colors.red;
      ctrl.team2.cups[1].isVisible = true;
      ctrl.team2.cups[1].color = Colors.red;
      ctrl.team2.cups[2].color = Colors.green;

      ctrl.setGameEnded();

      expect(ctrl.winner, 'Team 2');
      expect(ctrl.cupsRemainingWinner, 2);
      expect(ctrl.team2.wins, 1);
      expect(ctrl.team1.losses, 1);
    });

    testWidgets(
        'removeLastCupHit restores cup and clears lastCupHit for all players',
        (tester) async {
      final p1 = Player(name: 'A')..lastCupHit = true;
      final p2 = Player(name: 'B')..lastCupHit = true;
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [p1, p2], cupCount: 2),
        team2: _team(Colors.red, [Player(name: 'C')], cupCount: 2),
      );

      final cupIndex = ctrl.currentTeam.cups.first.index;
      ctrl.currentTeam.cups.first
        ..color = Colors.green
        ..isVisible = false;

      ctrl.removeLastCupHit(cupIndex);

      final restoredCup =
          ctrl.currentTeam.cups.firstWhere((cup) => cup.index == cupIndex);
      expect(restoredCup.color, ctrl.currentTeam.color);
      expect(restoredCup.isVisible, isTrue);
      expect(
          ctrl.currentTeam.players.every((p) => p.lastCupHit == false), isTrue);
    });

    testWidgets(
        'areAllCupsGone returns true only when current-team cups are all gone',
        (tester) async {
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'A')], cupCount: 2),
        team2: _team(Colors.red, [Player(name: 'B')], cupCount: 2),
      );

      ctrl.currentTeam.cups[0]
        ..isVisible = true
        ..color = ctrl.currentTeam.color;
      expect(ctrl.areAllCupsGone(), isFalse);

      for (final cup in ctrl.currentTeam.cups) {
        cup
          ..isVisible = false
          ..color = Colors.green;
      }
      expect(ctrl.areAllCupsGone(), isTrue);
    });

    testWidgets(
        'persistIfNotEnded skips persistence when game has already ended',
        (tester) async {
      final ctrl = await _loadController(
        tester,
        team1: _team(Colors.blue, [Player(name: 'A')], cupCount: 2),
        team2: _team(Colors.red, [Player(name: 'B')], cupCount: 2),
      );
      ctrl.gameEnded = true;

      await ctrl.persistIfNotEnded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefGameState), isNull);
    });
  });
}
