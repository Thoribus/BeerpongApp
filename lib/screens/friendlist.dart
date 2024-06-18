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
  late auth.User? user;

  @override
  void initState() {
    super.initState();
    user = auth.FirebaseAuth.instance.currentUser;
    _friends = FirestoreService().getFriends(user!.uid);
  }

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible:
          true, // User can dismiss the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter friend\'s ID'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final String friendId = controller.text.trim();
                if (friendId.isNotEmpty) {
                  _addFriend(context, friendId);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addFriend(BuildContext context, String friendId) async {
    try {
      await FirestoreService().addFriend(user!.uid, friendId);
      setState(() {
        _friends = FirestoreService().getFriends(user!.uid);
      });
    } catch (e) {
      print('Error adding friend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding friend: $e')),
      );
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
