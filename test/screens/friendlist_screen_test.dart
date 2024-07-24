import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/compare_stats_screen.dart';
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'friendlist_screen_test.mocks.dart';

@GenerateMocks([FirestoreService, auth.FirebaseAuth, auth.User])
void main() {
  late MockFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockAuthUser;
  late User testUser;
  late User friendUser;
  late Future<List<User>> friendsFuture;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockAuthUser = MockUser();
    testUser = User(
      id: '1',
      username: 'testUser',
      totalScore: 100.0,
      totalMisses: 10,
      totalAirballs: 5,
      totalThrows: 50,
      onFire: 0,
      defended: 0,
      hitLastCup: 0,
      cupsHit: [1, 2, 3],
      wins: 10,
      losses: 5,
      friends: ['2'],
      icon: Icons.person,
      iconColor: Colors.blue,
    );
    friendUser = User(
      id: '2',
      username: 'friendUser',
      totalScore: 80.0,
      totalMisses: 8,
      totalAirballs: 3,
      totalThrows: 40,
      onFire: 0,
      defended: 0,
      hitLastCup: 0,
      cupsHit: [4, 5, 6],
      wins: 8,
      losses: 7,
      friends: ['1'],
      icon: Icons.person,
      iconColor: Colors.red,
    );
    friendsFuture = Future.value([friendUser]);

    when(mockFirebaseAuth.currentUser).thenReturn(mockAuthUser);
    when(mockAuthUser.uid).thenReturn('1');
    when(mockFirestoreService.getUser(any)).thenAnswer((_) async => testUser);
    when(mockFirestoreService.getFriends(any)).thenAnswer((_) async => [friendUser]);
    when(mockFirestoreService.addFriend(any, any)).thenAnswer((_) async => Future.value());

    initializeMocks();
  });

  void initializeMocks() {
    when(mockFirestoreService.getUser('1')).thenAnswer((_) async => testUser);
    when(mockFirestoreService.getFriends('1')).thenAnswer((_) async => [friendUser]);
  }

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<auth.FirebaseAuth>.value(value: mockFirebaseAuth),
        Provider<FirestoreService>.value(value: mockFirestoreService),
      ],
      child: MaterialApp(
        home: const FriendsListScreen(),
      ),
    );
  }

  testWidgets('FriendsListScreen displays friends list', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Friends List'), findsOneWidget);
    expect(find.text('friendUser'), findsOneWidget);
  });

  testWidgets('FriendsListScreen allows adding friends', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Friend'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'newFriendId');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    verify(mockFirestoreService.addFriend('1', 'newFriendId')).called(1);
  });

  testWidgets('FriendsListScreen shows QR code and allows scanning', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Your ID: 1'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('Scan QR Code'));
    await tester.pumpAndSettle();

    // Assuming you have a way to mock BarcodeScanner.scan()
    // Mock the scan result and verify the addFriend call
  });

  testWidgets('FriendsListScreen navigates to ComparisonScreen on friend tap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('friendUser'));
    await tester.pumpAndSettle();

    expect(find.byType(ComparisonScreen), findsOneWidget);
  });

  testWidgets('FriendsListScreen displays ranking correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();

    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('friendUser'), findsOneWidget);
    expect(find.text('Wins'), findsOneWidget);
    expect(find.text('Win Rate: 53.33%'), findsOneWidget);
  });
}
