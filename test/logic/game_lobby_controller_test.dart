import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/home/game_lobby_controller.dart';

GameLobbyController makeController() => GameLobbyController(
      initialRules: {'rule1': false, 'rule2': true},
    );

Player namedPlayer(String name) => Player(name: name);

void main() {
  group('GameLobbyController pure logic', () {
    // ── canStartGame ─────────────────────────────────────────────────────────

    test('canStartGame returns false with no players', () {
      final ctrl = makeController();
      expect(ctrl.canStartGame(), isFalse);
    });

    test('canStartGame returns false when blue has player but red is empty', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer('Alice'));
      expect(ctrl.canStartGame(), isFalse);
    });

    test('canStartGame returns false when a player has empty name', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer(''));
      ctrl.playersRed.add(namedPlayer('Bob'));
      expect(ctrl.canStartGame(), isFalse);
    });

    test('canStartGame returns false when a player name is only whitespace', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer('   '));
      ctrl.playersRed.add(namedPlayer('Bob'));
      expect(ctrl.canStartGame(), isFalse);
    });

    test('canStartGame returns false when invitation is pending', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer('Alice'));
      ctrl.playersRed.add(namedPlayer('Bob'));
      ctrl.blueInvitationStatuses[0] = 'pending';
      expect(ctrl.canStartGame(), isFalse);
    });

    test('canStartGame returns true with valid named players on both teams', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer('Alice'));
      ctrl.playersRed.add(namedPlayer('Bob'));
      expect(ctrl.canStartGame(), isTrue);
    });

    // ── toggleRule ───────────────────────────────────────────────────────────

    test('toggleRule updates selectedRules', () {
      final ctrl = makeController();
      expect(ctrl.selectedRules['rule1'], isFalse);
      ctrl.toggleRule('rule1', true);
      expect(ctrl.selectedRules['rule1'], isTrue);
    });

    test('toggleRule notifies listeners', () {
      final ctrl = makeController();
      var notified = false;
      ctrl.addListener(() => notified = true);
      ctrl.toggleRule('rule2', false);
      expect(notified, isTrue);
    });

    // ── addPlayer ────────────────────────────────────────────────────────────

    test('addPlayer(true) adds player to blue team', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.addPlayer(true);
      expect(ctrl.playersBlue.length, 1);
      expect(ctrl.playersRed, isEmpty);
    });

    test('addPlayer(false) adds player to red team', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.addPlayer(false);
      expect(ctrl.playersRed.length, 1);
      expect(ctrl.playersBlue, isEmpty);
    });

    test('addPlayer adds player with empty name', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.addPlayer(true);
      expect(ctrl.playersBlue.first.name, '');
    });

    // ── removePlayer ─────────────────────────────────────────────────────────

    test('removePlayer(true, 0) removes from blue team', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer('Alice'));
      ctrl.playersBlue.add(namedPlayer('Bob'));
      ctrl.removePlayer(true, 0);
      expect(ctrl.playersBlue.length, 1);
      expect(ctrl.playersBlue.first.name, 'Bob');
    });

    test('removePlayer(false, 0) removes from red team', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersRed.add(namedPlayer('Carol'));
      ctrl.removePlayer(false, 0);
      expect(ctrl.playersRed, isEmpty);
    });

    // ── updatePlayerName ─────────────────────────────────────────────────────

    test('updatePlayerName updates player name at given index', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersBlue.add(namedPlayer(''));
      ctrl.updatePlayerName(true, 0, 'Alice');
      expect(ctrl.playersBlue.first.name, 'Alice');
    });

    test('updatePlayerName on red team updates correct player', () {
      final ctrl = makeController();
      ctrl.gameId = null;
      ctrl.playersRed.add(namedPlayer(''));
      ctrl.updatePlayerName(false, 0, 'Dave');
      expect(ctrl.playersRed.first.name, 'Dave');
    });

    // ── selectSelf ───────────────────────────────────────────────────────────

    test('selectSelf updates player name and user without Firestore', () async {
      final ctrl = makeController();
      ctrl.gameId = null; // updateGameDoc early-returns when gameId is null
      ctrl.playersBlue.add(namedPlayer(''));

      final user = User(id: 'u1', username: 'Alice');
      await ctrl.selectSelf(true, 0, user);

      expect(ctrl.playersBlue.first.name, 'Alice');
      expect(ctrl.playersBlue.first.user?.id, 'u1');
    });

    // ── selectedRules initialisation ─────────────────────────────────────────

    test('constructor copies initialRules into selectedRules', () {
      final ctrl = GameLobbyController(
        initialRules: {'island': true, 'rebuttal': false},
      );
      expect(ctrl.selectedRules['island'], isTrue);
      expect(ctrl.selectedRules['rebuttal'], isFalse);
    });
  });
}
