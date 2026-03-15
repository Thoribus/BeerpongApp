import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Provides the current user's data and handles sign-in/out flows.
class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  /// Sets the user directly — for use in tests only.
  // ignore: use_setters_to_change_properties
  void setUserForTesting(User user) {
    _user = user;
    notifyListeners();
  }

  /// Load the current user's data from Firestore.
  Future<void> loadUser() async {
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user = await FirestoreService.instance.getUser(currentUser.uid);
      notifyListeners();
    }
  }

  /// Updates the user's data in Firestore and locally.
  Future<void> updateUser(User user) async {
    _user = user;
    await FirestoreService.instance.updateUser(user);
    notifyListeners();
  }

  /// Clears local user data and signs out from Firebase & Google.
  Future<void> signOut() async {
    _user = null;
    await GoogleSignIn().signOut();
    await auth.FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  /// Signs in with Google OAuth. If the user is new, add them to Firestore.
  Future<void> signIn() async {
    final auth.User? authUser = await _signInWithGoogle();
    if (authUser == null) {
      _user = null;
      return;
    }

    // Check if user doc already exists
    final existingUser = await FirestoreService.instance.getUser(authUser.uid);
    if (existingUser == null) {
      // Create a new default user in Firestore
      final newUser = User(
        id: authUser.uid,
        username: authUser.displayName ?? 'Unknown',
      );
      await FirestoreService.instance.addUser(newUser);
      _user = newUser;
    } else {
      _user = existingUser;
    }
    notifyListeners();
  }

  /// Actual Google sign-in flow returning the Firebase user.
  Future<auth.User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;

      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = 
        await auth.FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      AppLogger.error('Error during Google Sign-In', e);
      rethrow;
    }
  }
}
