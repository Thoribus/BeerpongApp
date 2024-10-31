import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'compare_stats_screen.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import for SVG support

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  FriendsListScreenState createState() => FriendsListScreenState();
}

class FriendsListScreenState extends State<FriendsListScreen> {
  late Future<List<User>> _friends;
  late Future<User?> _userFuture;
  late auth.User? authUser;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedAttribute = 'Total Score'; // Default sorting attribute

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
                decoration:
                    const InputDecoration(hintText: 'Enter friend\'s ID'),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  FlutterClipboard.copy(authUser!.uid).then((value) =>
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Copied to Clipboard'))));
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
      if (!mounted) return;
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

  void _showComparisonScreen(User friend) {
    _userFuture.then((currentUser) {
      if (currentUser != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ComparisonScreen(
            currentUser: currentUser,
            friend: friend,
          ),
        ));
      }
    });
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
                  'Friends',
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
                  'Leaderboard',
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
                onTap: () => _showComparisonScreen(friend),
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

          // Sort friends based on the selected attribute
          friends.sort((a, b) {
            switch (_selectedAttribute) {
              case 'Total Score':
                return b.totalScore.compareTo(a.totalScore);
              case 'Win Rate':
                return b.winRate.compareTo(a.winRate);
              default:
                return 0; // No sorting
            }
          });

          return SingleChildScrollView(
            // Make the entire ranking page scrollable
            child: Column(
              children: [
                // Podium graphic
                SvgPicture.asset(
                  'assets/podium.svg', // Ensure this path is correct
                  width: double.infinity,
                  height: 150, // Adjust height as needed
                ),
                const SizedBox(
                    height: 10), // Space between the podium and the list

                // Dropdown for sorting attribute
                DropdownButton<String>(
                  value: _selectedAttribute,
                  items: <String>['Total Score', 'Win Rate']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAttribute = newValue!;
                    });
                  },
                  dropdownColor: Colors.black, // Dropdown background color
                  style: const TextStyle(
                      color: Colors.white), // Dropdown text color
                ),

                // The list of friends ranked
                ListView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling
                  shrinkWrap: true, // Wrap the list to prevent overflow
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    User friend = friends[index];
                    return ListTile(
                      leading: Text(
                        '${index + 1}',
                        style:
                            const TextStyle(color: Colors.amber, fontSize: 24),
                      ),
                      title: Text(
                        friend.username,
                        style: TextStyle(
                          color: friend.id == authUser!.uid
                              ? Colors.amber
                              : Colors.white,
                          fontWeight: friend.id == authUser!.uid
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _selectedAttribute == 'Total Score'
                            ? 'Total Score: ${friend.totalScore}'
                            : 'Win Rate: ${(friend.winRate * 100).toStringAsFixed(2)}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<List<User>> _fetchFriendsAndUser() async {
    List<User> friends = await FirestoreService().getFriends(authUser!.uid);
    User? currentUser = await FirestoreService().getUser(authUser!.uid);
    if (currentUser != null) {
      friends.insert(0, currentUser); // Add current user to the top of the list
    }
    return friends;
  }
}
