import 'package:beerpongapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'compare_stats_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../util/user_provider.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  FriendsListScreenState createState() => FriendsListScreenState();
}

class FriendsListScreenState extends State<FriendsListScreen> {
  late Future<List<User>> _friends;
  String _selectedAttribute = 'Total Score';
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      _friends = FirestoreService().getFriends(userProvider.user!.id);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController controller = TextEditingController();

    if (userProvider.user == null) {
      _showErrorSnackBar('You must be signed in to add friends.');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: _buildAddFriendDialogContent(controller, userProvider),
          actions: _buildAddFriendDialogActions(controller, userProvider),
        );
      },
    );
  }

  Widget _buildAddFriendDialogContent(
      TextEditingController controller, UserProvider userProvider) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter friend\'s ID'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                FlutterClipboard.copy(userProvider.user!.id).then((value) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to Clipboard'))));
              },
              child: Text(
                'Your ID: ${userProvider.user!.id}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              child: QrImageView(
                version: QrVersions.auto,
                data: userProvider.user!.id,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanQRCode,
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddFriendDialogActions(
      TextEditingController controller, UserProvider userProvider) {
    return [
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
            _addFriend(context, friendId, userProvider);
            Navigator.of(context).pop();
          }
        },
      ),
    ];
  }

  Future<void> _scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (!mounted) return;
      if (result.type == ResultType.Barcode) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        _addFriend(context, result.rawContent, userProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning QR code: $e');
    }
  }

  Future<void> _addFriend(
      BuildContext context, String friendId, UserProvider userProvider) async {
    try {
      await FirestoreService().addFriend(userProvider.user!.id, friendId);
      setState(() {
        _friends = FirestoreService().getFriends(userProvider.user!.id);
      });
    } catch (e) {
      _showErrorSnackBar('Error adding friend: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showComparisonScreen(User friend) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _showErrorSnackBar('You must be signed in to view comparisons.');
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ComparisonScreen(
        currentUser: userProvider.user!,
        friend: friend,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'You must be signed in to view your friends.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildPageSelector(),
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

  Widget _buildPageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageSelectorButton('Friends', 0),
        const VerticalDivider(
          color: Colors.white,
          width: 20,
          thickness: 2,
          indent: 5,
          endIndent: 5,
        ),
        _buildPageSelectorButton('Leaderboard', 1),
      ],
    );
  }

  Widget _buildPageSelectorButton(String title, int pageIndex) {
    return TextButton(
      onPressed: _currentPage == pageIndex
          ? null
          : () {
              _pageController.jumpToPage(pageIndex);
            },
      child: Text(
        title,
        style: TextStyle(
          color: _currentPage == pageIndex ? AppConstants.primaryColor : Colors.white,
        ),
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
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              User friend = snapshot.data![index];
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
          return _buildRankingList(snapshot.data!);
        }
      },
    );
  }

  Widget _buildRankingList(List<User> users) {
    users.sort((a, b) {
      switch (_selectedAttribute) {
        case 'Total Score':
          return b.totalScore.compareTo(a.totalScore);
        case 'Win Rate':
          return b.winRate.compareTo(a.winRate);
        default:
          return 0;
      }
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/podium.svg',
            width: double.infinity,
            height: 150,
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedAttribute,
            items: ['Total Score', 'Win Rate']
                .map<DropdownMenuItem<String>>((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedAttribute = newValue!;
              });
            },
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              return ListTile(
                leading: Text('${index + 1}',
                    style: const TextStyle(color: AppConstants.primaryColor, fontSize: 24)),
                title: Text(
                  user.username,
                  style: TextStyle(
                    color: user.id ==
                            Provider.of<UserProvider>(context, listen: false)
                                .user!
                                .id
                        ? AppConstants.primaryColor
                        : Colors.white,
                    fontWeight: user.id ==
                            Provider.of<UserProvider>(context, listen: false)
                                .user!
                                .id
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _selectedAttribute == 'Total Score'
                      ? 'Total Score: ${user.totalScore}'
                      : 'Win Rate: ${(user.winRate * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<User>> _fetchFriendsAndUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      return [];
    }

    List<User> friends =
        await FirestoreService().getFriends(userProvider.user!.id);
    friends.insert(0, userProvider.user!);
    return friends;
  }
}
