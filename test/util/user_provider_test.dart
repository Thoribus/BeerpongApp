import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'user_provider_test.mocks.dart';

@GenerateMocks([
  FirestoreService,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  auth.FirebaseAuth,
  auth.User,
  auth.UserCredential,
])
void main() {
  late UserProvider userProvider;
  late MockFirestoreService mockFirestoreService;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockGoogleSignIn = MockGoogleSignIn();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    userProvider = UserProvider();
    auth.FirebaseAuth.instance = mockFirebaseAuth as auth.FirebaseAuth;
  });

  group('UserProvider', () {
    test('loadUser loads user from Firestore and notifies listeners', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUid');
      when(mockFirestoreService.getUser('testUid'))
          .thenAnswer((_) async => User(id: 'testUid', username: 'testUser'));

      await userProvider.loadUser();

      expect(userProvider.user, isNotNull);
      expect(userProvider.user?.username, 'testUser');
    });

    test('updateUser updates user in Firestore and notifies listeners',
        () async {
      User user = User(id: 'testUid', username: 'testUser');
      when(mockFirestoreService.updateUser(user)).thenAnswer((_) async => null);

      await userProvider.updateUser(user);

      expect(userProvider.user, user);
      verify(mockFirestoreService.updateUser(user)).called(1);
    });

    test('signOut signs out from Google and Firebase, and notifies listeners',
        () async {
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => null);

      userProvider.signOut();

      expect(userProvider.user, isNull);
      verify(mockGoogleSignIn.signOut()).called(1);
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('signIn signs in with Google and notifies listeners', () async {
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication)
          .thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken)
          .thenReturn('accessToken');
      when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUid');
      when(mockUser.displayName).thenReturn('testUser');
      when(mockFirestoreService.getUser('testUid'))
          .thenAnswer((_) async => null);
      when(mockFirestoreService.addUser(any)).thenAnswer((_) async => null);

      userProvider.signIn();

      expect(userProvider.user, isNotNull);
      expect(userProvider.user?.username, 'testUser');
      verify(mockFirestoreService.addUser(any)).called(1);
    });

    test('signIn does not add user if already exists', () async {
      when(mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.authentication)
          .thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.accessToken)
          .thenReturn('accessToken');
      when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUid');
      when(mockUser.displayName).thenReturn('testUser');
      when(mockFirestoreService.getUser('testUid'))
          .thenAnswer((_) async => User(id: 'testUid', username: 'testUser'));

      userProvider.signIn();

      expect(userProvider.user, isNotNull);
      expect(userProvider.user?.username, 'testUser');
      verify(mockFirestoreService.addUser(any)).called(0);
    });
  });
}
