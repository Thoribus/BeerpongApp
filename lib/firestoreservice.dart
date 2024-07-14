import 'package:beerpongapp/models/game_statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/player.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User mapPlayerToUser(Player player, bool isWinner) {
    return User(
      id: player.user!.id,
      username: player.user!.username,
      totalScore: player.user!.totalScore += player.score,
      totalMisses: player.user!.totalMisses += player.misses,
      totalAirballs: player.user!.totalAirballs += player.airballs,
      totalThrows: player.user!.totalThrows += player.throws,
      onFire: player.user!.onFire += player.onFire,
      defended: player.user!.defended += player.defended,
      hitLastCup: player.user!.hitLastCup += player.lastCupHit ? 1 : 0,
      cupsHit: player.user!.cupsHit += player.cupsHit,
      wins: player.user!.wins += isWinner ? 1 : 0,
      losses: player.user!.losses += isWinner ? 0 : 1,
      friends: player.user!.friends,
      icon: player.user!.icon,
      iconColor: player.user!.iconColor,
    );
  }

  Future<void> saveGame({
    required List<Player> team1,
    required List<Player> team2,
    required String winner,
  }) async {
    try {
      List<String> participants = [
        ...team1.map((player) => player.user != null ? player.user!.id : ""),
        ...team2.map((player) => player.user != null ? player.user!.id : "")
      ];
      await _db.collection('games').add({
        'team1': team1.map((player) => player.toJson()).toList(),
        'team2': team2.map((player) => player.toJson()).toList(),
        'winner': winner,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': participants,
      });

      for (Player player in team1) {
        if (player.user != null) {
          User user = mapPlayerToUser(player, winner == 'Team 1');
          await updateUser(user);
        }
      }
      for (Player player in team2) {
        if (player.user != null) {
          User user = mapPlayerToUser(player, winner == 'Team 2');
          await updateUser(user);
        }
      }
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<List<GameStatistics>> retrieveGames() async {
    final user = auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return [];
    }
    print(user.uid);

    try {
      QuerySnapshot snapshot = await _db
          .collection('games')
          .where('participants', arrayContains: user.uid)
          .get();
      print(snapshot.docs.first.data() as Map<String, dynamic>);
      return snapshot.docs.map((doc) {
        return GameStatistics.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error retrieving games: $e');
      return [];
    }
  }

  // Convert Firestore Document to User model
  User _userFromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'],
      totalScore: data['totalScore'] ?? 0.0,
      totalMisses: data['totalMisses'] ?? 0,
      totalAirballs: data['totalAirballs'] ?? 0,
      totalThrows: data['totalThrows'] ?? 0,
      onFire: data['onFire'] ?? 0,
      defended: data['defended'] ?? 0,
      hitLastCup: data['hitLastCup'] ?? 0,
      cupsHit: List<int>.from(data['cupsHit'] ?? []),
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      friends: List<String>.from(data['friends'] ?? []),
      icon: IconData(data['icon'], fontFamily: 'MaterialIcons'),
      iconColor: Color(data['iconColor']),
    );
  }


  // Fetch friends of a user
  Future<List<User>> getFriends(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _db.collection('users').doc(userId).get();
      List<String> friendIds = List<String>.from(userDoc['friends']);

      List<User> friends = [];
      for (String friendId in friendIds) {
        DocumentSnapshot friendDoc =
            await _db.collection('users').doc(friendId).get();
        friends.add(_userFromFirestore(friendDoc));
      }
      return friends;
    } catch (e) {
      print('Error fetching friends: $e');
      rethrow;
    }
  }

  // Add a friend to a user's friend list
  Future<void> addFriend(String userId, String friendId) async {
    try {
      DocumentReference userDoc = _db.collection('users').doc(userId);
      DocumentReference friendDoc = _db.collection('users').doc(friendId);

      await _db.runTransaction((transaction) async {
        transaction.update(userDoc, {
          'friends': FieldValue.arrayUnion([friendId])
        });
        transaction.update(friendDoc, {
          'friends': FieldValue.arrayUnion([userId])
        });
      });
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
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

  // Add a new user to Firestore
  Future<void> addUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  // Update an existing user in Firestore
  Future<void> updateUser(User user) async {
    try {
      DocumentReference docRef = _db.collection('users').doc(user.id);
      DocumentSnapshot docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await addUser(user);
      } else {
        Map<String, dynamic> data = user.toJson();
        Map<String, dynamic> existingData = docSnapshot.data() as Map<String, dynamic>;

        // Add missing fields with their default values
        data.forEach((key, value) {
          if (!existingData.containsKey(key)) {
            existingData[key] = value;
          }
        });

        await docRef.update(existingData);
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete a user from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Fetch a user from Firestore
  Future<User?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return _userFromFirestore(doc);
      }
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
    return null;
  }
}