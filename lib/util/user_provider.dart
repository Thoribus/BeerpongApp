import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:beerpongapp/services/notification_service.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/app_logger.dart';
import 'package:beerpongapp/util/firestoreservice.dart';

/// Provides the current user's data and handles sign-in/out flows.
class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;

  /// True while the initial session is being restored from Firebase.
  /// The router redirect gate waits for this to become false.
  bool get isLoading => _isLoading;

  /// Sets the user directly — for use in tests only.
  // ignore: use_setters_to_change_properties
  void setUserForTesting(User user) {
    _user = user;
    notifyListeners();
  }

  /// Restores an existing session on app start.
  Future<void> loadUser() async {
    _isLoading = true;
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user = await FirestoreService.instance.getUser(currentUser.uid);
      if (_user != null) {
        unawaited(NotificationService.instance.initForUser(_user!.id));
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Updates the user's data in Firestore and locally.
  Future<void> updateUser(User user) async {
    _user = user;
    await FirestoreService.instance.updateUser(user);
    notifyListeners();
  }

  /// Re-reads the current user from Firestore and updates local state WITHOUT
  /// writing back to Firestore. Use this after operations that update Firestore
  /// directly (e.g. star purchases via transactions) to sync the local cache.
  ///
  /// Safe to call after closing a dialog — [notifyListeners] only rebuilds
  /// widgets, it does not trigger GoRouter navigation redirects unless a route
  /// guard's condition actually changes.
  Future<void> refreshUser() async {
    if (_user == null) return;
    final refreshed = await FirestoreService.instance.getUser(_user!.id);
    if (refreshed != null) {
      _user = refreshed;
      notifyListeners();
    }
  }

  /// Equips or unequips an in-game cosmetic item.
  /// [field] is 'activeCupSkin' or 'activeTableTheme'; pass null [itemId] to unequip.
  Future<void> equipItem({required String field, required String? itemId}) async {
    if (_user == null) return;
    await FirestoreService.instance
        .equipItem(userId: _user!.id, field: field, itemId: itemId);
    await refreshUser();
  }

  /// Claims [newUsername] atomically in Firestore and updates the local user.
  Future<void> claimUsername(String newUsername) async {
    if (_user == null) return;
    await FirestoreService.instance.claimUsername(
      newUsername: newUsername,
      oldUsernameLower: _user!.usernameLower,
      uid: _user!.id,
    );
    _user = _user!.copyWith(username: newUsername);
    notifyListeners();
  }

  /// Clears local user data and signs out from Firebase & Google.
  Future<void> signOut() async {
    if (_user != null) {
      await NotificationService.instance.removeTokenForUser(_user!.id);
    }
    _user = null;
    await GoogleSignIn().signOut();
    await auth.FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  // ─── Google ───────────────────────────────────────────────────────────────

  Future<void> signIn() async {
    final authUser = await _signInWithGoogle();
    if (authUser == null) return;
    await _onFirebaseUser(authUser);
  }

  Future<auth.User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result =
          await auth.FirebaseAuth.instance.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      AppLogger.error('Error during Google Sign-In', e);
      rethrow;
    }
  }

  // ─── Apple ────────────────────────────────────────────────────────────────

  Future<void> signInWithApple() async {
    final authUser = await _signInWithAppleOAuth();
    if (authUser == null) return;
    await _onFirebaseUser(authUser);
  }

  Future<auth.User?> _signInWithAppleOAuth() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final result = await auth.FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      return result.user;
    } catch (e) {
      AppLogger.error('Error during Apple Sign-In', e);
      rethrow;
    }
  }

  // ─── Email / Password ─────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final result = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) await _onFirebaseUser(result.user!);
    } catch (e) {
      AppLogger.error('Error during email sign-in', e);
      rethrow;
    }
  }

  Future<void> registerWithEmail(
      String email, String password, String username) async {
    try {
      final result = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _onFirebaseUser(result.user!, overrideUsername: username);
      }
    } catch (e) {
      AppLogger.error('Error during email registration', e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // ─── Shared ───────────────────────────────────────────────────────────────

  /// Loads-or-creates the Firestore user doc and registers FCM.
  Future<void> _onFirebaseUser(auth.User authUser,
      {String? overrideUsername}) async {
    final existing = await FirestoreService.instance.getUser(authUser.uid);
    if (existing == null) {
      final newUser = User(
        id: authUser.uid,
        username: overrideUsername ?? authUser.displayName ?? 'Player',
      );
      await FirestoreService.instance.addUser(newUser);
      _user = newUser;
    } else {
      _user = existing;
    }
    notifyListeners();
    unawaited(NotificationService.instance.initForUser(_user!.id));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256OfString(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
