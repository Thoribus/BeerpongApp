import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> loadUser() async {
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user = await FirestoreService().getUser(currentUser.uid);
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    _user = user;
    await FirestoreService().updateUser(user);
    notifyListeners();
  }

  void signOut() async {
    _user = null;
    await GoogleSignIn().signOut();
    auth.FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  void signIn() async {
    auth.User? authUser = await signInWithGoogle();
    if (authUser == null) {
      _user = null;
      return;
    } else {
      if (await FirestoreService().getUser(authUser.uid) == null) {
        FirestoreService()
            .addUser(User(id: authUser.uid, username: authUser.displayName!));
      } else {
        _user = await FirestoreService().getUser(authUser.uid);
      }
    }
    notifyListeners();
  }

  // Sign in with Google and return the authenticated user
  Future<auth.User?> signInWithGoogle() async {
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

      auth.UserCredential userCredential =
          await auth.FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }
}
