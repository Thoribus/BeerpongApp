import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/team.dart';

List<Cup> _cups(Color color, {int count = 10}) =>
    List.generate(count, (i) => Cup(index: i, color: color));

Team _team({Color color = Colors.blue, int cupCount = 10, bool rearranged = false}) => Team(
      color: color,
      players: [],
      cups: _cups(color, count: cupCount),
      isRearranged: rearranged,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CupLayout.buildCupsArea — default layout', () {
    testWidgets('renders without error for 10-cup team', (tester) async {
      final team = _team();
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      // 10 Visibility widgets wrapping each cup
      expect(find.byType(Visibility), findsNWidgets(10));
    });

    testWidgets('onCupTap is wired and triggered on tap', (tester) async {
      int tappedIndex = -1;
      final team = _team();
      await tester.pumpWidget(_wrap(
        CupLayout.buildCupsArea(
          team: team,
          onCupTap: (i) => tappedIndex = i,
        ),
      ));
      // Tap the first GestureDetector
      await tester.tap(find.byType(GestureDetector).first);
      expect(tappedIndex, greaterThanOrEqualTo(0));
    });

    testWidgets('no cup numbers shown when showNumbers = false (default)',
        (tester) async {
      final team = _team();
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      // No Text widgets with numeric cup labels
      expect(find.text('1'), findsNothing);
      expect(find.text('10'), findsNothing);
    });

    testWidgets('showNumbers = true shows cup index labels', (tester) async {
      final team = _team();
      await tester.pumpWidget(_wrap(
        CupLayout.buildCupsArea(team: team, showNumbers: true),
      ));
      // Cup indices are 1-based (index+1), so cup 0 → "1"
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('green cups do not show a number when showNumbers is true',
        (tester) async {
      final team = _team();
      team.cups[0].color = Colors.green;
      await tester.pumpWidget(_wrap(
        CupLayout.buildCupsArea(team: team, showNumbers: true),
      ));
      // Cup 0 is green; label "1" (index+1) should NOT appear.
      expect(find.text('1'), findsNothing);
    });

    testWidgets('skinColor override is accepted without error', (tester) async {
      final team = _team();
      await tester.pumpWidget(_wrap(
        CupLayout.buildCupsArea(team: team, skinColor: Colors.purple),
      ));
      expect(find.byType(Visibility), findsNWidgets(10));
    });
  });

  group('CupLayout.buildCupsArea — rearranged layout', () {
    testWidgets('renders 6-cup rearranged layout', (tester) async {
      final team = _team(cupCount: 6, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(6));
    });

    testWidgets('renders 5-cup rearranged layout', (tester) async {
      final team = _team(cupCount: 5, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(5));
    });

    testWidgets('renders 4-cup rearranged layout', (tester) async {
      final team = _team(cupCount: 4, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(4));
    });

    testWidgets('renders 3-cup rearranged layout', (tester) async {
      final team = _team(cupCount: 3, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(3));
    });

    testWidgets('renders 2-cup rearranged layout', (tester) async {
      final team = _team(cupCount: 2, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(2));
    });

    testWidgets('renders 1-cup default (fallthrough) rearranged layout',
        (tester) async {
      final team = _team(cupCount: 1, rearranged: true);
      await tester.pumpWidget(_wrap(CupLayout.buildCupsArea(team: team)));
      expect(find.byType(Visibility), findsNWidgets(1));
    });
  });
}
