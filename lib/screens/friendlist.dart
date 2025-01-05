import 'package:beerpongapp/constants.dart'; // For AppConstants.primaryColor (optional)
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'compare_stats_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

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

  /// Prompts the user to add a friend by ID or by scanning a QR code.
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
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: _buildAddFriendDialogContent(controller, userProvider),
          actions: _buildAddFriendDialogActions(controller, userProvider),
        );
      },
    );
  }

  Widget _buildAddFriendDialogContent(
    TextEditingController controller,
    UserProvider userProvider,
  ) {
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
              decoration: const InputDecoration(hintText: "Enter friend's ID"),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                FlutterClipboard.copy(userProvider.user!.id).then(
                  (value) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to Clipboard')),
                  ),
                );
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
    TextEditingController controller,
    UserProvider userProvider,
  ) {
    return [
      TextButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
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

  /// Scans a QR code and attempts to add a friend with the scanned ID.
  Future<void> _scanQRCode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (!mounted) return;
      if (result.type == ResultType.Barcode) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        _addFriend(context, result.rawContent, userProvider);
        Navigator.of(context).pop(); // close the dialog
      }
    } catch (e) {
      _showErrorSnackBar('Error scanning QR code: $e');
    }
  }

  /// Adds a friend by ID, refreshes the Future list.
  Future<void> _addFriend(
    BuildContext ctx,
    String friendId,
    UserProvider userProvider,
  ) async {
    try {
      await FirestoreService().addFriend(userProvider.user!.id, friendId);
      setState(() {
        _friends = FirestoreService().getFriends(userProvider.user!.id);
      });
    } catch (e) {
      _showErrorSnackBar('Error adding friend: $e');
    }
  }

  /// Shows a red error SnackBar with the given message.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Navigates to the comparison screen for the friend and the current user.
  void _showComparisonScreen(User friend) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _showErrorSnackBar('You must be signed in to view comparisons.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComparisonScreen(
          currentUser: userProvider.user!,
          friend: friend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.user == null) {
      return Scaffold(
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
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
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

  /// Builds the top row for switching between “Friends” and “Leaderboard” pages.
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
          : () => _pageController.jumpToPage(pageIndex),
      child: Text(
        title,
        style: TextStyle(
          color: _currentPage == pageIndex
              ? AppConstants.primaryColor
              : Colors.white,
        ),
      ),
    );
  }

  /// Shows the “Friends” page with a FutureBuilder of the user’s friends.
  Widget _buildFriendsListPage() {
    return FutureBuilder<List<User>>(
      future: _friends,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No friends found.',
                  style: TextStyle(color: Colors.white)));
        }

        final friends = snapshot.data!;
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (ctx, index) {
            final friend = friends[index];
            return ListTile(
              leading: _buildFriendAvatar(friend),
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
      },
    );
  }

  /// Builds the “Leaderboard” page, which includes the user + friends sorted by an attribute.
  Widget _buildRankingPage() {
    return FutureBuilder<List<User>>(
      future: _fetchFriendsAndUser(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No friends found.',
                  style: TextStyle(color: Colors.white)));
        }

        final friends = snapshot.data!;
        // Sort by the selected attribute
        friends.sort((a, b) {
          switch (_selectedAttribute) {
            case 'Total Score':
              return b.totalScore.compareTo(a.totalScore);
            case 'Win Rate':
              return b.winRate.compareTo(a.winRate);
            default:
              return 0;
          }
        });

        return Column(
          children: [
            // Podium area
            Stack(
              alignment: Alignment.center,
              children: [
                // If you have a podium.svg or something similar:
                SvgPicture.asset(
                  'assets/podium.svg',
                  width: double.infinity,
                  height: MediaQuery.of(ctx).size.height * 0.4,
                ),
                Positioned(
                  top: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (friends.length > 1)
                        _buildPodiumPosition(friends[1], 2),
                      if (friends.isNotEmpty)
                        _buildPodiumPosition(friends[0], 1),
                      if (friends.length > 2)
                        _buildPodiumPosition(friends[2], 3),
                    ],
                  ),
                ),
              ],
            ),

            // Sorting dropdown
            DropdownButton<String>(
              value: _selectedAttribute,
              items: <String>['Total Score', 'Win Rate']
                  .map<DropdownMenuItem<String>>((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedAttribute = newValue!);
              },
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),

            // List from 4th place onwards
            Expanded(
              child: ListView.builder(
                itemCount: (friends.length <= 3) ? 0 : (friends.length - 3),
                itemBuilder: (ctx2, index) {
                  final friend = friends[index + 3];
                  return ListTile(
                    leading: Text(
                      '${index + 4}',
                      style: const TextStyle(color: Colors.amber, fontSize: 18),
                    ),
                    title: Row(
                      children: [
                        _buildFriendAvatar(friend, radius: 20),
                        const SizedBox(width: 10),
                        Text(
                          friend.username,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    trailing: Text(
                      _selectedAttribute == 'Total Score'
                          ? friend.totalScore.toString()
                          : '${(friend.winRate * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a circle avatar for a friend based on `avatarKey`.
  Widget _buildFriendAvatar(User friend, {double radius = 30}) {
    final assetPath = _mapAvatarKeyToAsset(friend.avatarKey);
    if (assetPath.isEmpty) {
      // fallback if no avatarKey
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        child: const Icon(Icons.person, color: Colors.white),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        child: ClipOval(
          child: SvgPicture.asset(
            assetPath,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
          ),
        ),
      );
    }
  }

  /// Builds a single user for the top 3 podium positions.
  Widget _buildPodiumPosition(User user, int position) {
    // Larger avatar for 1st place
    final radius = (position == 1) ? 45.0 : 35.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          _buildFriendAvatar(user, radius: radius),
          const SizedBox(height: 5),
          Text(user.username, style: const TextStyle(color: Colors.white)),
          Text(
            _selectedAttribute == 'Total Score'
                ? '${user.totalScore}'
                : '${(user.winRate * 100).toStringAsFixed(2)}%',
            style: const TextStyle(color: Colors.amber),
          ),
        ],
      ),
    );
  }

  /// Returns a combined list of currentUser + their friends, for the leaderboard.
  Future<List<User>> _fetchFriendsAndUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      return [];
    }

    final userId = userProvider.user!.id;
    final friends = await FirestoreService().getFriends(userId);

    // Insert the current user at index 0
    return [userProvider.user!, ...friends];
  }

  /// Maps avatarKey -> local asset path (e.g. 'cat' -> 'assets/avatars/cat.png').
  String _mapAvatarKeyToAsset(String avatarKey) {
    if (avatarKey.isEmpty) return '';
    return 'assets/avatars/$avatarKey.svg';
  }
}
