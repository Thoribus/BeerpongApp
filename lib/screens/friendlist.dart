import 'package:beerpongapp/constants.dart'; // For AppConstants.primaryColor (optional)
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'compare_stats_screen.dart';

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
          backgroundColor: Colors.amberAccent,
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
    );
  }

  /// Builds the top row for switching between “Friends” and “Leaderboard” pages.
  Widget _buildPageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageSelectorButton('Friendlist', 0),
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

        final userProvider = Provider.of<UserProvider>(context);

        return ListView(
          children: [
            // Insert the ListTile for the current user data here
            // Insert the ListTile for the current user data here
            if (userProvider.user != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.amber,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: _buildFriendAvatar(userProvider.user!),
                  title: Text(
                    userProvider.user!.username,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Title: ${userProvider.user!.title}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _showAddFriendDialog(
                        context), // Trigger the add friend dialog
                    child: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      radius: 20, // Adjust size as needed
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20, // Adjust icon size as needed
                      ),
                    ),
                  ),
                  onTap: () => _showComparisonScreen(userProvider.user!),
                ),
              ),

            // Insert the ListTiles for friends below
            ListView.builder(
              shrinkWrap: true, // To prevent nested scrolling
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling in the inner ListView
              itemCount: friends.length,
              itemBuilder: (ctx, index) {
                final friend = friends[index];
                return FutureBuilder<List<UserStatsInGame>>(
                  future: FirestoreService().retrieveUserStatsWithDate(friend),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white)));
                    }
                    final lastGame = snapshot.data ?? [];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: _buildFriendAvatar(friend),
                        title: Text(
                          friend.username,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Title: ${friend.title}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'last seen',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastGame.isNotEmpty
                                  ? DateFormat('dd.MM.yyyy')
                                      .format(lastGame.first.date)
                                  : 'No games',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showComparisonScreen(friend),
                      ),
                    );
                  },
                );
              },
            ),
          ],
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No friends found.'));
        }

        final friends = snapshot.data!;
        friends.sort((a, b) => _selectedAttribute == 'Total Score'
            ? b.totalScore.compareTo(a.totalScore)
            : b.winRate.compareTo(a.winRate));

        return Column(
          children: [
            _buildPodium(friends),
            _buildSortingDropdown(),
            Expanded(child: _buildRankingList(friends)),
          ],
        );
      },
    );
  }

  Widget _buildPodium(List<User> friends) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[800], // Fallback background color
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // SVG Background
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/podium_background.svg', // Replace with your SVG path
                  fit: BoxFit.cover,
                ),
              ),

              // Second place (Left)
              if (friends.length > 1)
                Positioned(
                  left: 40,
                  bottom: 100, // Adjust height of podium
                  child:
                      _buildPodiumUser(friends[1], 2, Colors.blue, height: 100),
                ),

              // First place (Center, Highest)
              if (friends.isNotEmpty)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 50, // Center
                  bottom: 130, // Highest podium height
                  child: _buildPodiumUser(friends[0], 1, Colors.amber,
                      crown: true, height: 120),
                ),

              // Third place (Right)
              if (friends.length > 2)
                Positioned(
                  right: 20,
                  bottom: 90, // Lowest podium position
                  child:
                      _buildPodiumUser(friends[2], 3, Colors.green, height: 80),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumUser(User user, int rank, Color borderColor,
      {bool crown = false, double height = 100}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: borderColor,
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Colors.black,
                child: ClipOval(
                  child: SvgPicture.asset(
                    _mapAvatarKeyToAsset(user.avatarKey),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (crown)
              Positioned(
                top: -5,
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            user.username,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          _selectedAttribute == 'Total Score'
              ? user.totalScore.toString()
              : '${(user.winRate * 100).toStringAsFixed(2)}%',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSortingDropdown() {
    return // Sorting dropdown
        ListTile(
      tileColor: Colors.amber,
      leading: const Text(
        'Rank',
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      trailing: DropdownButton<String>(
        value: _selectedAttribute,
        items: <String>['Total Score', 'Win Rate']
            .map<DropdownMenuItem<String>>((val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val, style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() => _selectedAttribute = newValue!);
        },
        dropdownColor: Colors.amber,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildRankingList(List<User> friends) {
    return ListView.builder(
      itemCount: friends.length - 3,
      itemBuilder: (ctx, index) {
        final user = friends[index + 3];
        return ListTile(
          leading: Text('${index + 4}',
              style: const TextStyle(color: Colors.amber, fontSize: 18)),
          title: Row(
            children: [
              _buildFriendAvatar(user, radius: 20),
              const SizedBox(width: 10),
              Text(user.username, style: const TextStyle(color: Colors.white)),
            ],
          ),
          trailing: Text(
            _selectedAttribute == 'Total Score'
                ? user.totalScore.toString()
                : '${(user.winRate * 100).toStringAsFixed(2)}%',
            style: const TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildFriendAvatar(User friend, {double radius = 30}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: ClipOval(
        child: SvgPicture.asset(
          _mapAvatarKeyToAsset(friend.avatarKey),
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
        ),
      ),
    );
  }

  Future<List<User>> _fetchFriendsAndUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return [];
    final friends = await FirestoreService().getFriends(userProvider.user!.id);
    return [userProvider.user!, ...friends];
  }

  String _mapAvatarKeyToAsset(String avatarKey) {
    return 'assets/avatars/$avatarKey.svg';
  }
}
