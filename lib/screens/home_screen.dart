import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:beerpongapp/screens/account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/models/user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            kToolbarHeight + 20), // Adjust height as needed
        child: CustomAppBar(),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 3.0),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.asset(
                          'assets/beerpong.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SelectionScreen()),
                            );
                          },
                          child: const Text('Neues Spiel'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    height: 20), // Add some spacing between the elements
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Statistik screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                  icon: Icons.bar_chart,
                  label: 'Statistik',
                ),
                _buildElevatedButton(
                  context: context,
                  onPressed: () async {
                    User? user = await getUser('123');
                    // Navigate to Freundesliste screen
                  },
                  icon: Icons.people_alt_rounded,
                  label: 'Freundesliste',
                ),
                _buildElevatedButton(
                  context: context,
                  onPressed: () {
                    // Navigate to Einstellungen screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountScreen(),
                      ),
                    );
                  },
                  icon: Icons.settings,
                  label: 'Einstellungen',
                ),
                StreamBuilder(
                    stream: auth.FirebaseAuth.instance.authStateChanges(),
                    builder: (BuildContext context,
                        AsyncSnapshot<auth.User?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                  'Signed in as ${snapshot.data?.displayName}'),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  await GoogleSignIn().signOut();
                                  auth.FirebaseAuth.instance.signOut();
                                },
                                child: const Text('Sign out'),
                              ),
                            ],
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () {
                              signInWithGoogle();
                            },
                            child: const Text('Sign in with Google'),
                          );
                        }
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
                StreamBuilder(
                    stream: auth.FirebaseAuth.instance.authStateChanges(),
                    builder: (BuildContext context,
                        AsyncSnapshot<auth.User?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final User user = User(
                                    id: snapshot.data!.uid,
                                    username: snapshot.data!.displayName!,
                                  );
                                  print(user);
                                  addUser(user);
                                },
                                child: const Text('Create User in DB'),
                              ),
                            ],
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () {
                              signInWithGoogle();
                            },
                            child: const Text('Sign in with Google'),
                          );
                        }
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildElevatedButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.75,
    margin: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.amber, width: 3.0),
      borderRadius: BorderRadius.circular(15.0),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.7),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

signInWithGoogle() async {
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
}

Future<void> addUser(User user) async {
  try {
    print(user.id + user.username);
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    await _db.collection('users').doc(user.id).set({
      'username': user.username,
      'totalScore': user.totalScore,
      'totalMisses': user.totalMisses,
      'totalAirballs': user.totalAirballs,
      'cupsHit': user.cupsHit,
      'wins': user.wins,
      'losses': user.losses,
    });
  } catch (e) {
    print('Error adding user: $e');
  }
}

Future<void> updateUser(User user) async {
  try {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    await _db.collection('users').doc(user.id).update({
      'username': user.username,
      'totalScore': user.totalScore,
      'totalMisses': user.totalMisses,
      'totalAirballs': user.totalAirballs,
      'cupsHit': user.cupsHit,
      'wins': user.wins,
      'losses': user.losses,
    });
  } catch (e) {
    print('Error updating user: $e');
  }
}

Future<void> deleteUser(User user) async {
  try {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    await _db.collection('users').doc(user.id).delete();
  } catch (e) {
    print('Error deleting user: $e');
  }
}

Future<User?> getUser(String id) async {
  try {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final DocumentSnapshot doc = await _db.collection('users').doc(id).get();
    if (doc.exists) {
      return User(
        id: doc.id,
        username: doc['username'],
        totalScore: doc['totalScore'],
        totalMisses: doc['totalMisses'],
        totalAirballs: doc['totalAirballs'],
        cupsHit: doc['cupsHit'],
        wins: doc['wins'],
        losses: doc['losses'],
      );
    }
  } catch (e) {
    print('Error getting user: $e');
  }
  return null;
}

class CustomAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.withOpacity(0.5), // Amber color with low opacity
      child: AppBar(
        title: const Text('Beerpong App'),
        backgroundColor:
            Colors.transparent, // Make app bar background transparent
        elevation: 3, // Remove elevation
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            print('Menu Icon Pressed');
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sports_bar_rounded),
            onPressed: () {
              print('Beer Icon Pressed');
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              print('Settings Icon Pressed');
            },
          ),
        ],
      ),
    );
  }
}
