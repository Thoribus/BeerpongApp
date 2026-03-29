import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/game_persistence.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Team _team(Color color, String playerName) {
  return Team(
    color: color,
    players: [Player(name: playerName)],
    cups: List.generate(10, (i) => Cup(index: i, color: color)),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen restores saved state and navigates to stats tab',
      (tester) async {
    final savedTeam1 = _team(Colors.blue, 'Saved Blue');
    final savedTeam2 = _team(Colors.red, 'Saved Red');

    await GamePersistence.saveGameState(
      id: 'saved-id',
      team1: savedTeam1,
      team2: savedTeam2,
      isTeamOneTurn: false, // Team 2 turn
      islandShotActive: false,
      invitations: const [],
      selectedRules: const {'Island': true},
      tournamentId: 'tour-1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<UserProvider>.value(
        value: UserProvider(),
        child: MaterialApp(
          home: GameScreen(
            // These fallback values should be ignored because saved state exists.
            id: 'fallback-id',
            team1: _team(Colors.blue, 'Fallback Blue'),
            team2: _team(Colors.red, 'Fallback Red'),
            selectedRules: const {'Island': false},
            startingTeam: true,
            invitations: const [],
            tournamentId: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Team 2's Turn"), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Team Statistics'), findsOneWidget);
    expect(find.text('Saved Blue'), findsOneWidget);
    expect(find.text('Saved Red'), findsOneWidget);
  });
}
