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

class DummyUser {
  final String username;
  final String avatarUrl;

  DummyUser({
    required this.username,
    required this.avatarUrl,
  });
}

enum ActionType { wonGame, achievement }

class _FriendAction {
  final DummyUser user;
  final ActionType type;
  final String description;
  final DateTime date;

  _FriendAction({
    required this.user,
    required this.type,
    required this.description,
    required this.date,
  });
}

Color _getActionColor(ActionType type) {
  switch (type) {
    case ActionType.wonGame:
      return Colors.greenAccent.shade100;
    case ActionType.achievement:
      return Colors.lightBlueAccent.shade100;
    default:
      return Colors.grey.shade200;
  }
}

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

  Color _getLastSeenColor(DateTime? lastSeen) {
    if (lastSeen == null) return Colors.grey;
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inDays < 1) return Colors.green;
    if (diff.inDays < 7) return Colors.orange;
    return Colors.grey;
  }

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
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.grey[200], // Card background style
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add a Friend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Enter friend's ID",
                        hintStyle: const TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.orange, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.deepOrange, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        FlutterClipboard.copy(userProvider.user!.id).then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to Clipboard')),
                          ),
                        );
                      },
                      child: Text(
                        'Your ID: ${userProvider.user!.id}',
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: QrImageView(
                          version: QrVersions.auto,
                          data: userProvider.user!.id,
                          size: MediaQuery.of(context).size.width * 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _scanQRCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Scan QR Code',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.black)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final String friendId = controller.text.trim();
                            if (friendId.isNotEmpty) {
                              _addFriend(context, friendId, userProvider);
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
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
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'You must be signed in to view your friends.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                _buildSocialPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelector() {
    final List<String> pages = ["Friendlist", "Leaderboard", "Socials"];

    return Container(
      height: 48,
      width: double.infinity,
      //margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        //borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: pages.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (_currentPage != index) {
                    _pageController.jumpToPage(index);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
                style: const TextStyle(color: Colors.black)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No friends found.',
                style: TextStyle(color: Colors.black)),
          );
        }

        final friends = snapshot.data!;
        final userProvider = Provider.of<UserProvider>(context);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            if (userProvider.user != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.grey[200],
                elevation: 1,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: _buildCompactFriendAvatar(userProvider.user!),
                  title: Text(
                    userProvider.user!.username,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  subtitle: Text(
                    'Title: ${userProvider.user!.title}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _showAddFriendDialog(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      radius: 16,
                      child: Icon(Icons.add, color: Colors.black, size: 16),
                    ),
                  ),
                  onTap: () => _showComparisonScreen(userProvider.user!),
                ),
              ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                              style: const TextStyle(color: Colors.black)));
                    }

                    final lastGame = snapshot.data ?? [];
                    final lastSeenColor = _getLastSeenColor(
                        lastGame.isNotEmpty ? lastGame.first.date : null);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Colors.grey[200],
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minVerticalPadding: 0,
                        visualDensity: const VisualDensity(
                            horizontal: 0, vertical: -3), // Reduces height
                        leading: _buildCompactFriendAvatar(friend),
                        title: Text(
                          friend.username,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black),
                        ),
                        subtitle: Text(
                          'Title: ${friend.title}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'last seen',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastGame.isNotEmpty
                                  ? DateFormat('dd.MM.yyyy')
                                      .format(lastGame.first.date)
                                  : 'No games',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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

  Widget _buildSocialPage() {
    final List<_FriendAction> dummyActions = [
      _FriendAction(
        user: DummyUser(username: 'Alice', avatarUrl: ''),
        type: ActionType.wonGame,
        description: 'won a game of Classic Mode',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _FriendAction(
        user: DummyUser(username: 'Bob', avatarUrl: ''),
        type: ActionType.achievement,
        description: 'unlocked the “Sharpshooter” achievement',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _FriendAction(
        user: DummyUser(username: 'Carol', avatarUrl: ''),
        type: ActionType.wonGame,
        description: 'won a game of Speed Mode',
        date: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: dummyActions.length,
      itemBuilder: (context, index) {
        final action = dummyActions[index];
        final bgColor = _getActionColor(action.type);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: bgColor,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Text(
                action.user.username[0],
                style: const TextStyle(color: Colors.black),
              ),
            ),
            title: Text(
              action.user.username,
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
            subtitle: Text(
              action.description,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Date',
                    style: TextStyle(fontSize: 10, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd.MM.yyyy').format(action.date),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
          ),
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
                    user.mapAvatarKeyToAsset(),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (crown)
              const Positioned(
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
            style: const TextStyle(color: Colors.black),
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
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              Text(user.username, style: const TextStyle(color: Colors.black)),
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
          friend.mapAvatarKeyToAsset(),
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
        ),
      ),
    );
  }

  Widget _buildCompactFriendAvatar(User user) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: ClipOval(
        child: _buildFriendAvatar(user), // Uses your existing avatar logic
      ),
    );
  }

  Future<List<User>> _fetchFriendsAndUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return [];
    final friends = await FirestoreService().getFriends(userProvider.user!.id);
    return [userProvider.user!, ...friends];
  }
}
