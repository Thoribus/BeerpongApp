import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/widgets/new_game_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'new_game_dialog_test.mocks.dart';

@GenerateMocks([
  FirestoreService,
  auth.FirebaseAuth,
  auth.User,
  NavigatorObserver,
])
void main() {
  late MockFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late NavigatorObserver mockObserver;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockObserver = MockNavigatorObserver();

    auth.FirebaseAuth.instance = mockFirebaseAuth;
  });

  Future<void> _buildDialog(
    WidgetTester tester, {
    required int team,
    required List<String> initialNames,
    required int numPlayers,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                child: const Text('Show Dialog'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return NewGameDialog(
                        team: team,
                        initialNames: initialNames,
                        numPlayers: numPlayers,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        navigatorObservers: [mockObserver],
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
  }

  group('NewGameDialog', () {
    testWidgets('displays initial names and allows editing', (tester) async {
      await _buildDialog(tester,
          team: 1, initialNames: ['Player 1', 'Player 2'], numPlayers: 2);

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'New Player 1');
      expect(find.text('New Player 1'), findsOneWidget);
    });

    testWidgets('calls selectFromFriendList and updates TextField',
        (tester) async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('userId');
      when(mockFirestoreService.getUser('userId'))
          .thenAnswer((_) async => User(id: 'userId', username: 'User 1'));
      when(mockFirestoreService.getFriends('userId')).thenAnswer(
          (_) async => [User(id: 'friendId', username: 'Friend 1')]);

      await _buildDialog(tester, team: 1, initialNames: [], numPlayers: 2);

      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Friend 1'));
      await tester.pumpAndSettle();

      expect(find.text('Friend 1'), findsOneWidget);
    });

    testWidgets('saves the entered names and returns them on SAVE',
        (tester) async {
      await _buildDialog(tester, team: 1, initialNames: [], numPlayers: 2);

      await tester.enterText(find.byType(TextField).first, 'Player 1');
      await tester.enterText(find.byType(TextField).last, 'Player 2');

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      verify(mockObserver.didPop(any, any));
    });
  });
}
