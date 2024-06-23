import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';
import 'base_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter friend\'s ID'),
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
      backgroundColor: Colors.black,
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
                  leading: GestureDetector(
                    onTap: () => _showIconPicker(context, friend),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Colors.blue, // Replace with dynamic color
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    friend.username,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Total Score: ${friend.totalScore}',
                    style: TextStyle(color: Colors.grey),
                  ),
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

  void _showIconPicker(BuildContext context, User friend) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Icon and Color for ${friend.username}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _iconList.length,
                  itemBuilder: (BuildContext context, int index) {
                    IconData icon = _iconList[index];
                    return GestureDetector(
                      onTap: () {
                        // Implement logic to save icon and color for friend
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            Colors.blue, // Replace with dynamic color
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<IconData> _iconList = [
    Icons.person,
    Icons.favorite,
    Icons.star,
    Icons.directions_bike,
    Icons.ac_unit,
    Icons.airplanemode_active,
    Icons.access_alarm,
    Icons.book,
    Icons.brush,
    Icons.cake,
  ];
}
