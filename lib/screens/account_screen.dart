import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirestoreService().getUser(currentUser.uid).then((value) {
        setState(() {
          user = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Center(
        child: StreamBuilder(
            stream: auth.FirebaseAuth.instance.authStateChanges(),
            builder:
                (BuildContext context, AsyncSnapshot<auth.User?> snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Text('Signed in as ${snapshot.data?.displayName}'),
                      Text("User ID: ${snapshot.data?.uid}"),
                      Text("Total Score: ${user?.totalScore}"),
                      Text("Total Misses: ${user?.totalMisses}"),
                      Text("Total Airballs: ${user?.totalAirballs}"),
                      Text("Cups Hit: ${user?.cupsHit}"),
                      Text("Wins: ${user?.wins}"),
                      Text("Losses: ${user?.losses}"),
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
                    onPressed: () async {
                      auth.User? authUser = await FirestoreService().signInWithGoogle();
                      final User user = User(
                        id: authUser!.uid,
                        username: authUser.displayName!,
                      );
                      if (await FirestoreService().getUser(user.id) == null) {
                        FirestoreService().addUser(user);
                      }
                    },
                    child: const Text('Sign in with Google'),
                  );
                }
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }

}
