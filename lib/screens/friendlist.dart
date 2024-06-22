import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter friend\'s ID'),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  FlutterClipboard.copy(user!.uid).then((value) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to Clipboard'))));
                },
                child: Text(
                  'Your ID: ${user!.uid}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              QrImageView(
                version: QrVersions.auto,
                data: user!.uid,
                size: 300.0,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _scanQRCode,
                child: const Text('Scan QR Code'),
              ),
            ],
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

  Future<void> _scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        _addFriend(context, result.rawContent);
        Navigator.of(context).pop();  // Close the dialog after scanning
      }
    } catch (e) {
      print('Error scanning QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning QR code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
          ),
        ],
      ),
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
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: friend.iconColor,
                    child: Icon(friend.icon, size: 30, color: Colors.white),
                  ),
                  title: Text(
                    friend.username,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Total Score: ${friend.totalScore}',
                    style: const TextStyle(color: Colors.grey),
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
}
