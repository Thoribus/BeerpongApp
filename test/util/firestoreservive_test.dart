import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot, auth.FirebaseAuth, auth.User])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;
  late MockQuerySnapshot mockQuerySnapshot;
  late FirestoreService firestoreService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    mockQuerySnapshot = MockQuerySnapshot();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    firestoreService = FirestoreService();

    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
    when(mockDocument.update(any)).thenAnswer((_) async => null);
    when(mockDocument.set(any)).thenAnswer((_) async => null);
    when(mockDocument.delete()).thenAnswer((_) async => null);
    when(mockCollection.add(any)).thenAnswer((_) async => mockDocument);
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('testUid');
  });

  group('FirestoreService', () {
    test('saveGame updates users and adds game to Firestore', () async {
      Player player1 = Player(name: 'Player 1', score: 10, user: User(id: 'user1', username: 'User 1'));
      Player player2 = Player(name: 'Player 2', score: 5, user: User(id: 'user2', username: 'User 2'));
      List<Player> team1 = [player1];
      List<Player> team2 = [player2];

      when(mockFirestore.collection('games')).thenReturn(mockCollection);
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocument);

      await firestoreService.saveGame(team1: team1, team2: team2, winner: 'Team 1');

      verify(mockCollection.add(any)).called(1);
      verify(mockDocument.update(any)).called(2);
    });

    test('retrieveGames returns list of games', () async {
      Map<String, dynamic> gameData = {
        'timestamp': Timestamp.now(),
        'winner': 'Team 1',
        'team1': [
          {'name': 'Player 1', 'score': 10}
        ],
        'team2': [
          {'name': 'Player 2', 'score': 5}
        ],
        'participants': ['testUid']
      };

      when(mockCollection.where('participants', arrayContains: 'testUid')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockSnapshot]);
      when(mockSnapshot.data()).thenReturn(gameData);

      List<GameStatistics> games = await firestoreService.retrieveGames();

      expect(games.length, 1);
      expect(games.first.winningTeam, 'Team 1');
    });

    test('addUser adds a new user to Firestore', () async {
      User user = User(id: 'user1', username: 'User 1');

      await firestoreService.addUser(user);

      verify(mockDocument.set(user.toJson())).called(1);
    });

    test('updateUser updates an existing user in Firestore', () async {
      User user = User(id: 'user1', username: 'User 1');

      await firestoreService.updateUser(user);

      verify(mockDocument.update(user.toJson())).called(1);
    });

    test('deleteUser deletes a user from Firestore', () async {
      String userId = 'user1';

      await firestoreService.deleteUser(userId);

      verify(mockDocument.delete()).called(1);
    });

    test('getUser returns user from Firestore', () async {
      Map<String, dynamic> userData = {
        'username': 'User 1',
        'totalScore': 0.0,
        'totalMisses': 0,
        'totalAirballs': 0,
        'totalThrows': 0,
        'onFire': 0,
        'defended': 0,
        'hitLastCup': 0,
        'cupsHit': [],
        'wins': 0,
        'losses': 0,
        'friends': [],
        'icon': Icons.person.codePoint,
        'iconColor': Colors.blue.value,
      };

      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn(userData);

      User? user = await firestoreService.getUser('user1');

      expect(user, isNotNull);
      expect(user?.username, 'User 1');
    });

    test('getUser returns null if user does not exist', () async {
      when(mockSnapshot.exists).thenReturn(false);

      User? user = await firestoreService.getUser('user1');

      expect(user, isNull);
    });

    test('addFriend adds a friend to user\'s friend list', () async {
      String userId = 'user1';
      String friendId = 'friend1';

      await firestoreService.addFriend(userId, friendId);

      verify(mockDocument.update({
        'friends': FieldValue.arrayUnion([friendId])
      })).called(1);
    });

    test('getFriends returns list of user\'s friends', () async {
      Map<String, dynamic> userData = {
        'username': 'User 1',
        'totalScore': 0.0,
        'totalMisses': 0,
        'totalAirballs': 0,
        'totalThrows': 0,
        'onFire': 0,
        'defended': 0,
        'hitLastCup': 0,
        'cupsHit': [],
        'wins': 0,
        'losses': 0,
        'friends': ['friend1'],
        'icon': Icons.person.codePoint,
        'iconColor': Colors.blue.value,
      };

      Map<String, dynamic> friendData = {
        'username': 'Friend 1',
        'totalScore': 0.0,
        'totalMisses': 0,
        'totalAirballs': 0,
        'totalThrows': 0,
        'onFire': 0,
        'defended': 0,
        'hitLastCup': 0,
        'cupsHit': [],
        'wins': 0,
        'losses': 0,
        'friends': [],
        'icon': Icons.person.codePoint,
        'iconColor': Colors.blue.value,
      };

      when(mockSnapshot.data()).thenReturn(userData);
      when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(mockDocument.data()).thenReturn(friendData);

      List<User> friends = await firestoreService.getFriends('user1');

      expect(friends.length, 1);
      expect(friends.first.username, 'Friend 1');
    });
  });
}
