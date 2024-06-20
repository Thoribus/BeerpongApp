import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<User>> getFriends(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(userId).get();
      List<String> friendIds = List<String>.from(userDoc['friends']);

      List<User> friends = [];
      for (String friendId in friendIds) {
        DocumentSnapshot friendDoc =
            await _db.collection('users').doc(friendId).get();
        Map<String, dynamic> data = friendDoc.data() as Map<String, dynamic>;
        friends.add(User(
            id: friendDoc.id,
            username: data['username'],
            totalScore: data['totalScore'],
            totalMisses: data['totalMisses'],
            totalThrows: data['totalThrows'],
            totalAirballs: data['totalAirballs'],
            cupsHit: List<int>.from(data['cupsHit']),
            wins: data['wins'],
            losses: data['losses']));
      }
      return friends;
    } catch (e) {
      print('Error fetching friends: $e');
      rethrow;
    }
  }

  Future<void> addFriend(String userId, String friendId) async {
    try {
      DocumentReference userDoc = _db.collection('users').doc(userId);
      await userDoc.update({
        'friends': FieldValue.arrayUnion([friendId])
      });
      DocumentReference friendDoc = _db.collection('users').doc(friendId);
      await friendDoc.update({
        'friends': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }

  Future<auth.User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    auth.UserCredential user =
        await auth.FirebaseAuth.instance.signInWithCredential(credential);
    print(user.user?.uid);
    return user.user;
  }

  Future<void> addUser(User user) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('users').doc(user.id).set({
        'username': user.username,
        'totalScore': user.totalScore,
        'totalMisses': user.totalMisses,
        'totalAirballs': user.totalAirballs,
        'totalThrows': user.totalThrows,
        'cupsHit': user.cupsHit,
        'wins': user.wins,
        'losses': user.losses,
        'friends': user.friends,
      });
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('users').doc(user.id).update({
        'username': user.username,
        'totalScore': user.totalScore,
        'totalMisses': user.totalMisses,
        'totalAirballs': user.totalAirballs,
        'totalThrows': user.totalThrows,
        'cupsHit': user.cupsHit,
        'wins': user.wins,
        'losses': user.losses,
        'friends': user.friends,
      });
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> deleteUser(User user) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      await db.collection('users').doc(user.id).delete();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<User?> getUser(String id) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final DocumentSnapshot doc = await db.collection('users').doc(id).get();
      if (doc.exists) {
        return User(
          id: doc.id,
          username: doc['username'],
          totalScore: doc['totalScore'],
          totalMisses: doc['totalMisses'],
          totalAirballs: doc['totalAirballs'],
          totalThrows: doc['totalThrows'],
          cupsHit: List<int>.from(doc['cupsHit']),
          wins: doc['wins'],
          losses: doc['losses'],
          friends: List<String>.from(doc['friends']),
        );
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }
}
