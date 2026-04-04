import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

Team _makeTeam(String name, Color color) => Team(
      color: color,
      players: [Player(name: name)],
      cups: List.generate(3, (i) => Cup(index: i, color: color)),
    );

TournamentMatch _makeMatch({Team? team1, Team? team2, Team? winner, bool played = false}) {
  final t1 = team1 ?? _makeTeam('A', Colors.blue);
  final t2 = team2 ?? _makeTeam('B', Colors.red);
  return TournamentMatch(
    id: 'match-1',
    team1: t1,
    team2: t2,
    winner: winner,
    played: played,
    round: 1,
    selectedRules: const {'Island': true},
    invitations: const ['inv-1'],
  );
}

void main() {
  group('Tournament toJson / fromJson', () {
    test('round-trip preserves basic fields', () {
      final t = Tournament(
        id: 'tournament-1',
        name: 'Test Cup',
        teams: [_makeTeam('A', Colors.blue), _makeTeam('B', Colors.red)],
        matches: [],
        started: true,
        finished: false,
        createdAt: DateTime.utc(2026, 1, 15),
      );

      final json = t.toJson();
      final restored = Tournament.fromJson(json);

      expect(restored.id, 'tournament-1');
      expect(restored.name, 'Test Cup');
      expect(restored.started, isTrue);
      expect(restored.finished, isFalse);
      expect(restored.teams.length, 2);
    });

    test('toJson does not include matches (Firestore manages them separately)', () {
      final teamA = _makeTeam('A', Colors.blue);
      final teamB = _makeTeam('B', Colors.red);
      final match = _makeMatch(team1: teamA, team2: teamB, played: true, winner: teamA);

      final t = Tournament(
        id: 't1',
        name: 'Cup',
        teams: [teamA, teamB],
        matches: [match],
      );

      final json = t.toJson();
      // matches are intentionally omitted from the JSON payload
      expect(json.containsKey('matches'), isFalse);
    });

    test('toJson includes participantIds', () {
      final teamA = _makeTeam('A', Colors.blue);
      final t = Tournament(
        id: 't1',
        name: 'Cup',
        teams: [teamA],
        matches: [],
      );
      final json = t.toJson();
      expect(json.containsKey('participantIds'), isTrue);
    });

    test('fromJson defaults to roundRobin type when type is unknown', () {
      final json = <String, dynamic>{
        'id': 't1',
        'name': 'Cup',
        'type': 'UnknownType',
        'teams': [],
        'matches': [],
        'started': false,
        'finished': false,
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      };
      final t = Tournament.fromJson(json);
      expect(t.type, TournamentType.roundRobin);
    });

    test('fromJson handles missing createdAt gracefully', () {
      final json = <String, dynamic>{
        'id': 't1',
        'name': 'Cup',
        'type': 'TournamentType.roundRobin',
        'teams': [],
        'matches': [],
        'started': false,
        'finished': false,
        // no createdAt
      };
      // Should not throw
      final t = Tournament.fromJson(json);
      expect(t.id, 't1');
    });
  });

  group('Tournament.copyWith', () {
    test('preserves all unchanged fields', () {
      final original = Tournament(
        id: 't1',
        name: 'Original',
        teams: [],
        matches: [],
        started: false,
        finished: false,
      );
      final copy = original.copyWith(name: 'Updated');
      expect(copy.id, 't1');
      expect(copy.name, 'Updated');
      expect(copy.started, isFalse);
    });

    test('can mark tournament as started', () {
      final t = Tournament(id: 't1', name: 'Cup', teams: [], matches: []);
      final started = t.copyWith(started: true);
      expect(started.started, isTrue);
    });

    test('can mark tournament as finished', () {
      final t = Tournament(id: 't1', name: 'Cup', teams: [], matches: []);
      final finished = t.copyWith(finished: true);
      expect(finished.finished, isTrue);
    });
  });

  group('TournamentMatch toJson / fromJson', () {
    test('round-trip preserves id, round, played', () {
      final match = _makeMatch(played: true);
      final json = match.toJson();
      final restored = TournamentMatch.fromJson(json);

      expect(restored.id, 'match-1');
      expect(restored.round, 1);
      expect(restored.played, isTrue);
    });

    test('round-trip preserves selectedRules', () {
      final match = _makeMatch();
      final json = match.toJson();
      final restored = TournamentMatch.fromJson(json);
      expect(restored.selectedRules['Island'], isTrue);
    });

    test('round-trip preserves invitations', () {
      final match = _makeMatch();
      final json = match.toJson();
      final restored = TournamentMatch.fromJson(json);
      expect(restored.invitations, contains('inv-1'));
    });

    test('winner is null when not set', () {
      final match = _makeMatch(played: false);
      final json = match.toJson();
      final restored = TournamentMatch.fromJson(json);
      expect(restored.winner, isNull);
    });

    test('winner is restored when set', () {
      final teamA = _makeTeam('A', Colors.blue);
      final teamB = _makeTeam('B', Colors.red);
      final match = _makeMatch(team1: teamA, team2: teamB, winner: teamA, played: true);
      final json = match.toJson();
      final restored = TournamentMatch.fromJson(json);
      expect(restored.winner, isNotNull);
      expect(restored.winner!.players.first.name, 'A');
    });

    test('fromJson defaults to empty selectedRules and invitations when absent', () {
      final teamA = _makeTeam('A', Colors.blue);
      final teamB = _makeTeam('B', Colors.red);
      final json = <String, dynamic>{
        'id': 'm1',
        'team1': teamA.toJson(),
        'team2': teamB.toJson(),
        'round': 0,
        'played': false,
      };
      final match = TournamentMatch.fromJson(json);
      expect(match.selectedRules, isEmpty);
      expect(match.invitations, isEmpty);
    });
  });

  group('TournamentMatch.copyWith', () {
    test('can update played status', () {
      final match = _makeMatch(played: false);
      final updated = match.copyWith(played: true);
      expect(updated.played, isTrue);
      expect(updated.id, 'match-1');
    });

    test('can set winner', () {
      final teamA = _makeTeam('A', Colors.blue);
      final match = _makeMatch();
      final updated = match.copyWith(winner: teamA);
      expect(updated.winner, isNotNull);
      expect(updated.winner!.players.first.name, 'A');
    });

    test('unchanged fields are preserved', () {
      final match = _makeMatch();
      final updated = match.copyWith(round: 5);
      expect(updated.round, 5);
      expect(updated.id, 'match-1');
      expect(updated.played, isFalse);
    });
  });

  group('TeamStanding toJson / fromJson', () {
    test('round-trip preserves wins and losses', () {
      final team = _makeTeam('A', Colors.blue);
      final standing = TeamStanding(team: team, wins: 3, losses: 1);
      final json = standing.toJson();
      final restored = TeamStanding.fromJson(json);

      expect(restored.wins, 3);
      expect(restored.losses, 1);
    });

    test('fromJson defaults wins and losses to 0 when absent', () {
      final team = _makeTeam('A', Colors.blue);
      final json = <String, dynamic>{'team': team.toJson()};
      final restored = TeamStanding.fromJson(json);
      expect(restored.wins, 0);
      expect(restored.losses, 0);
    });

    test('wins and losses are mutable', () {
      final team = _makeTeam('A', Colors.blue);
      final standing = TeamStanding(team: team);
      standing.wins = 5;
      standing.losses = 2;
      expect(standing.wins, 5);
      expect(standing.losses, 2);
    });
  });
}
