import 'package:beerpongapp/models/cup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildHost(Cup cup, {required VoidCallback onTap, int? hitCount}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: cup.widget(onTap: onTap, hitCount: hitCount),
      ),
    ),
  );
}

void main() {
  group('Cup.widget', () {
    testWidgets('calls onTap for visible cups', (tester) async {
      var tapped = false;
      final cup = Cup(index: 0, color: Colors.blue);

      await tester.pumpWidget(
        _buildHost(cup, onTap: () => tapped = true),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows hitCount text when provided', (tester) async {
      final cup = Cup(index: 1, color: Colors.red);

      await tester.pumpWidget(
        _buildHost(cup, onTap: () {}, hitCount: 4),
      );

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('does not render an interactable cup when invisible',
        (tester) async {
      final cup = Cup(index: 2, color: Colors.green, isVisible: false);

      await tester.pumpWidget(
        _buildHost(cup, onTap: () {}, hitCount: 9),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(GestureDetector).hitTestable(), findsNothing);
      expect(find.text('9', skipOffstage: false), findsOneWidget);
    });
  });
}
