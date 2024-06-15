import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';

class FriendsListScreen extends StatefulWidget {

  const FriendsListScreen({super.key});

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  late Future<List<User>> _friends;

  @override
  void initState() {
    super.initState();
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    _friends = FirestoreService().getFriends(currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: FutureBuilder<List<User>>(
        future: _friends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No friends found.'));
          } else {
            List<User> friends = snapshot.data!;
            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                User friend = friends[index];
                return ListTile(
                  title: Text(friend.username),
                  subtitle: Text('Total Score: ${friend.totalScore}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
