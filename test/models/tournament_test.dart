import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

Team _makeTeam(String name, Color color) => Team(
      color: color,
      players: [Player(name: name)],
      cups: List.generate(10, (i) => Cup(index: i, color: color)),
    );

void main() {
  group('generateRoundRobinMatches', () {
    test('produces n*(n-1)/2 matches for n teams', () {
      final teams = [
        _makeTeam('Team A', Colors.blue),
        _makeTeam('Team B', Colors.red),
        _makeTeam('Team C', Colors.green),
        _makeTeam('Team D', Colors.orange),
      ];
      final matches = generateRoundRobinMatches(teams, {}, []);
      // 4 teams → 4*3/2 = 6 matches
      expect(matches.length, 6);
    });

    test('every pair appears exactly once', () {
      final teams = [
        _makeTeam('Team A', Colors.blue),
        _makeTeam('Team B', Colors.red),
        _makeTeam('Team C', Colors.green),
      ];
      final matches = generateRoundRobinMatches(teams, {}, []);
      final pairs = matches
          .map((m) => {m.team1.players.first.name, m.team2.players.first.name})
          .toList();

      expect(pairs.length, 3); // 3*2/2
      expect(pairs.any((p) => p.containsAll(['Team A', 'Team B'])), isTrue);
      expect(pairs.any((p) => p.containsAll(['Team A', 'Team C'])), isTrue);
      expect(pairs.any((p) => p.containsAll(['Team B', 'Team C'])), isTrue);
    });

    test('returns empty list for 0 teams', () {
      final matches = generateRoundRobinMatches([], {}, []);
      expect(matches, isEmpty);
    });

    test('returns empty list for 1 team', () {
      final matches = generateRoundRobinMatches([_makeTeam('Solo', Colors.blue)], {}, []);
      expect(matches, isEmpty);
    });
  });

  group('computeStandings', () {
    test('counts wins and losses correctly', () {
      final teamA = _makeTeam('Team A', Colors.blue);
      final teamB = _makeTeam('Team B', Colors.red);

      final match = TournamentMatch(
        id: 'm1',
        team1: teamA,
        team2: teamB,
        winner: teamA,
        played: true,
      );

      final standings = computeStandings([teamA, teamB], [match]);
      final standingA = standings.firstWhere(
        (s) => s.team.players.first.name == 'Team A',
      );
      final standingB = standings.firstWhere(
        (s) => s.team.players.first.name == 'Team B',
      );

      expect(standingA.wins, 1);
      expect(standingA.losses, 0);
      expect(standingB.wins, 0);
      expect(standingB.losses, 1);
    });

    test('unplayed matches do not affect standings', () {
      final teamA = _makeTeam('Team A', Colors.blue);
      final teamB = _makeTeam('Team B', Colors.red);

      final match = TournamentMatch(
        id: 'm1',
        team1: teamA,
        team2: teamB,
        played: false,
      );

      final standings = computeStandings([teamA, teamB], [match]);
      for (final s in standings) {
        expect(s.wins, 0);
        expect(s.losses, 0);
      }
    });
  });
}
