import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';
import 'base_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';


class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  late Future<List<User>> _friends;
  late Future<User?> _userFuture;
  late auth.User? authUser;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    authUser = auth.FirebaseAuth.instance.currentUser;
    _userFuture = FirestoreService().getUser(authUser!.uid);
    _friends = FirestoreService().getFriends(authUser!.uid);
    _pageController.addListener(_handlePageChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    int page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
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
                  FlutterClipboard.copy(authUser!.uid).then((value) =>
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to Clipboard'))));
                },
                child: Text(
                  'Your ID: ${authUser!.uid}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              QrImageView(
                version: QrVersions.auto,
                data: authUser!.uid,
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

  Future<void> _scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        _addFriend(context, result.rawContent);
        Navigator.of(context).pop(); // Close the dialog after scanning
      }
    } catch (e) {
      print('Error scanning QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning QR code: $e')),
      );
    }
  }

  Future<void> _addFriend(BuildContext context, String friendId) async {
    try {
      await FirestoreService().addFriend(authUser!.uid, friendId);
      setState(() {
        _friends = FirestoreService().getFriends(authUser!.uid);
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
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _currentPage == 0
                    ? null
                    : () {
                        _pageController.jumpToPage(0);
                      },
                child: Text(
                  'Friends List',
                  style: TextStyle(
                    color: _currentPage == 0 ? Colors.amber : Colors.white,
                  ),
                ),
              ),
              const VerticalDivider(
                color: Colors.white,
                width: 20,
                thickness: 2,
                indent: 5,
                endIndent: 5,
              ),
              TextButton(
                onPressed: _currentPage == 1
                    ? null
                    : () {
                        _pageController.jumpToPage(1);
                      },
                child: Text(
                  'Ranking',
                  style: TextStyle(
                    color: _currentPage == 1 ? Colors.amber : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              children: [
                _buildFriendsListPage(),
                _buildRankingPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFriendsListPage() {
    return FutureBuilder<List<User>>(
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
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: friend.iconColor,
                    child: Icon(friend.icon, size: 30, color: Colors.white),
                  ),
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
    );
  }

  Widget _buildRankingPage() {
    return FutureBuilder<List<User>>(
      future: _fetchFriendsAndUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No friends found.'));
        } else {
          List<User> friends = snapshot.data!;
          friends.sort((a, b) => b.winRate.compareTo(a.winRate));
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              User friend = friends[index];
              bool isCurrentUser = friend.id == authUser!.uid;
              return ListTile(
                leading: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.amber, fontSize: 24),
                ),
                title: Text(
                  friend.username,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.amber : Colors.white,
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  'Win Rate: ${(friend.winRate * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
                tileColor: isCurrentUser ? Colors.grey[200] : Colors.black,
              );
            },
          );
        }
      },
    );
  }

  Future<List<User>> _fetchFriendsAndUser() async {
    final user = await _userFuture;
    List<User> friends = await _friends;
    if (user != null) {
      if (!friends.contains(user)) {
        friends.add(user);
      }
    }
    return friends;
  }
}
