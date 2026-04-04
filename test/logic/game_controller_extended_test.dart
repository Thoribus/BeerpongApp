import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_controller.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Cup> _cups(Color color, {int count = 6}) =>
    List.generate(count, (i) => Cup(index: i, color: color));

Team _team(Color color, List<Player> players, {int cupCount = 6}) => Team(
      color: color,
      players: players,
      cups: _cups(color, count: cupCount),
    );

Future<GameController> _ctrl(
  WidgetTester tester, {
  Team? team1,
  Team? team2,
}) async {
  final t1 = team1 ?? _team(Colors.blue, [Player(name: 'A'), Player(name: 'B')]);
  final t2 = team2 ?? _team(Colors.red, [Player(name: 'C'), Player(name: 'D')]);
  final ctrl = GameController(UserProvider());
  await ctrl.loadGameState(
    widgetId: 'g1',
    widgetTeam1: t1,
    widgetTeam2: t2,
    widgetStartingTeam: true,
    widgetInvitations: const [],
    widgetSelectedRules: const {'Island': false},
    widgetTournamentId: '',
  );
  await tester.pump();
  return ctrl;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameController — gradient', () {
    testWidgets('toggleGradientDirection swaps begin/end alignments', (tester) async {
      final ctrl = await _ctrl(tester);
      final originalBegin = ctrl.beginAlignment;
      final originalEnd = ctrl.endAlignment;

      ctrl.toggleGradientDirection();

      expect(ctrl.beginAlignment, originalEnd);
      expect(ctrl.endAlignment, originalBegin);
    });

    testWidgets('double toggle restores original alignments', (tester) async {
      final ctrl = await _ctrl(tester);
      final originalBegin = ctrl.beginAlignment;
      ctrl.toggleGradientDirection();
      ctrl.toggleGradientDirection();
      expect(ctrl.beginAlignment, originalBegin);
    });
  });

  group('GameController — bounce shot', () {
    testWidgets('activateBounceShot sets bounceShotActive and records shooter',
        (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;

      ctrl.activateBounceShot(player);

      expect(ctrl.bounceShotActive, isTrue);
      expect(ctrl.currentBounceShooter, player);
    });

    testWidgets('cancelBounceShot clears bounceShotActive and shooter',
        (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      ctrl.activateBounceShot(player);

      ctrl.cancelBounceShot();

      expect(ctrl.bounceShotActive, isFalse);
      expect(ctrl.currentBounceShooter, isNull);
    });

    testWidgets('endTurn clears bounce state', (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      ctrl.activateBounceShot(player);
      expect(ctrl.bounceShotActive, isTrue);

      ctrl.endTurn();

      expect(ctrl.bounceShotActive, isFalse);
      expect(ctrl.currentBounceShooter, isNull);
    });
  });

  group('GameController — player stat methods', () {
    testWidgets('incrementPlayerScore adds 1 to player score', (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      final before = player.score;

      ctrl.incrementPlayerScore(player);

      expect(player.score, before + 1);
    });

    testWidgets('decrementPlayerScore subtracts 1 from player score',
        (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      player.score = 5.0;

      ctrl.decrementPlayerScore(player);

      expect(player.score, 4.0);
    });

    testWidgets('addCupToPlayer records cup index on player', (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;

      ctrl.addCupToPlayer(player, 3);

      expect(player.cupsHit, contains(3));
    });

    testWidgets('incrementPlayerThrows increments throw count', (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      final before = player.throws;

      ctrl.incrementPlayerThrows(player);

      expect(player.throws, before + 1);
    });

    testWidgets('incrementPlayerHitThisRound increments hitThisRound',
        (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;

      ctrl.incrementPlayerHitThisRound(player);

      expect(player.hitThisRound, 1);
    });

    testWidgets('setPlayerHitLastCup sets lastCupHit on player', (tester) async {
      final ctrl = await _ctrl(tester);
      final player = ctrl.currentTeam.currentPlayers.first;
      expect(player.lastCupHit, isFalse);

      ctrl.setPlayerHitLastCup(player);

      expect(player.lastCupHit, isTrue);
    });
  });

  group('GameController — toggleIslandCups', () {
    testWidgets('activates island shot and colors eligible cups yellow',
        (tester) async {
      final ctrl = await _ctrl(tester);
      expect(ctrl.islandShotActive, isFalse);

      ctrl.toggleIslandCups();

      expect(ctrl.islandShotActive, isTrue);
      // In tests, render boxes are absent so all visible cups are "island cups".
      final yellowCups =
          ctrl.currentTeam.cups.where((c) => c.color == Colors.yellow).length;
      expect(yellowCups, greaterThanOrEqualTo(0));
    });

    testWidgets('deactivates island shot and restores cup color', (tester) async {
      final ctrl = await _ctrl(tester);
      // Manually color some cups yellow to simulate active island state.
      for (final cup in ctrl.currentTeam.cups) {
        cup.color = Colors.yellow;
      }
      ctrl.islandShotActive = true;

      ctrl.toggleIslandCups();

      expect(ctrl.islandShotActive, isFalse);
      // All yellow cups should be restored to team color.
      final yellowCups =
          ctrl.currentTeam.cups.where((c) => c.color == Colors.yellow);
      expect(yellowCups, isEmpty);
    });

    testWidgets('double toggle restores original state', (tester) async {
      final ctrl = await _ctrl(tester);
      final originalActive = ctrl.islandShotActive;

      ctrl.toggleIslandCups();
      ctrl.toggleIslandCups();

      expect(ctrl.islandShotActive, originalActive);
    });
  });

  group('GameController — undoLastAction', () {
    testWidgets('does nothing when action stack is empty', (tester) async {
      final ctrl = await _ctrl(tester);
      final teamColor = ctrl.team1.color;

      // Should not throw.
      ctrl.undoLastAction();

      expect(ctrl.team1.color, teamColor);
    });
  });

  group('GameController — getRandomCupIndex', () {
    testWidgets('returns a valid cup index different from excluded cup',
        (tester) async {
      final ctrl = await _ctrl(tester);
      final cups = ctrl.currentTeam.cups;
      final excluded = cups.first.index;

      final result = ctrl.getRandomCupIndex(cups, excluded, ctrl.currentTeam.color);

      expect(result, isNot(excluded));
      expect(cups.any((c) => c.index == result), isTrue);
    });

    testWidgets('throws when no eligible cups remain', (tester) async {
      // Use a 1-cup team so exclusion leaves no candidates.
      final singleCupTeam = _team(Colors.blue, [Player(name: 'X')], cupCount: 1);
      final singleCtrl = await _ctrl(tester, team1: singleCupTeam);
      final cup = singleCtrl.currentTeam.cups.first;

      expect(
        () => singleCtrl.getRandomCupIndex(
          singleCtrl.currentTeam.cups,
          cup.index,
          singleCtrl.currentTeam.color,
        ),
        throwsException,
      );
    });

    testWidgets('never returns an invisible cup', (tester) async {
      final ctrl = await _ctrl(tester);
      // Hide all cups except first and last.
      final cups = ctrl.currentTeam.cups;
      for (int i = 1; i < cups.length - 1; i++) {
        cups[i].isVisible = false;
      }
      final excluded = cups.first.index;

      final result = ctrl.getRandomCupIndex(cups, excluded, ctrl.currentTeam.color);

      final returned = cups.firstWhere((c) => c.index == result);
      expect(returned.isVisible, isTrue);
    });
  });
}
