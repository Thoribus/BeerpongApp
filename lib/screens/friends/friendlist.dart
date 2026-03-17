import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:beerpongapp/util/route_args.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_tab_bar.dart';

enum ActionType { wonGame, achievement }

class FriendAction {
  final User user;
  final ActionType type;
  final String description;
  final DateTime date;

  FriendAction({
    required this.user,
    required this.type,
    required this.description,
    required this.date,
  });
}

Color getActionColor(ActionType type) {
  switch (type) {
    case ActionType.wonGame:
      return Colors.greenAccent.shade100;
    case ActionType.achievement:
      return Colors.lightBlueAccent.shade100;
  }
}

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  FriendsListScreenState createState() => FriendsListScreenState();
}

class FriendsListScreenState extends State<FriendsListScreen> {
  Future<List<User>>? _friends;
  Future<List<User>>? _friendsWithUser;
  String _selectedAttribute = 'Total Score';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null && _friends == null) {
      _friends = FirestoreService.instance.getFriends(user.id);
      _friendsWithUser = _friends!.then((friends) => [user, ...friends]);
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

    final c = AppColors.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: c.card,
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
                    Text(
                      'Add a Friend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Enter friend's ID",
                        hintStyle: const TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: c.surface,
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
                      style: TextStyle(fontSize: 14, color: c.onBackground),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Clipboard.setData(ClipboardData(text: userProvider.user!.id)).then(
                          (_) => messenger.showSnackBar(
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
                      onPressed: () => _scanQRCode(ctx),
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
                          child: Text('Cancel',
                              style: TextStyle(color: c.onBackground)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final String friendId = controller.text.trim();
                            if (friendId.isNotEmpty) {
                              _addFriend(context, friendId, userProvider);
                              Navigator.of(ctx).pop();
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

  /// Scans a QR code and attempts to add a friend with the scanned ID.
  Future<void> _scanQRCode(BuildContext dialogCtx) async {
    try {
      final result = await BarcodeScanner.scan();
      if (!mounted) return;
      if (result.type == ResultType.Barcode) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await _addFriend(context, result.rawContent, userProvider);
        if (!mounted) return;
        Navigator.of(dialogCtx).pop(); // close the dialog
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
      await FirestoreService.instance.addFriend(userProvider.user!.id, friendId);
      setState(() {
        _friends = FirestoreService.instance.getFriends(userProvider.user!.id);
        _friendsWithUser = _friends!.then((friends) => [userProvider.user!, ...friends]);
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

    context.push('/compare', extra: ComparisonArgs(
      currentUser: userProvider.user!,
      friend: friend,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final c = AppColors.of(context);

    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your friends',
                style: TextStyle(color: c.onBackground, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async => userProvider.signIn(),
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
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
    return AppTabBar(
      tabs: const ['Friendlist', 'Leaderboard', 'Socials'],
      selectedIndex: _currentPage,
      onTabSelected: (index) {
        if (_currentPage != index) {
          _pageController.jumpToPage(index);
        }
      },
      backgroundColor: Colors.grey.shade800,
    );
  }

  Widget _buildFriendsListPage() {
    return FutureBuilder<List<User>>(
      future: _friends,
      builder: (context, snapshot) {
        final c = AppColors.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: TextStyle(color: c.onBackground)),
          );
        }
        final friends = snapshot.data ?? [];
        final userProvider = Provider.of<UserProvider>(context);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            if (userProvider.user != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: c.card,
                elevation: 1,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: _buildCompactFriendAvatar(userProvider.user!),
                  title: Text(
                    userProvider.user!.username,
                    style: TextStyle(fontSize: 14, color: c.onBackground),
                  ),
                  subtitle: Text(
                    'Title: ${userProvider.user!.title}',
                    style: TextStyle(fontSize: 12, color: c.subtle),
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
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No friends yet. Add one using the + button above.',
                    style: TextStyle(color: c.subtle, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              itemBuilder: (ctx, index) {
                final friend = friends[index];
                return FutureBuilder<List<UserStatsInGame>>(
                  future: FirestoreService.instance.retrieveUserStatsWithDate(friend),
                  builder: (context, snapshot) {
                    final c = AppColors.of(context);
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: TextStyle(color: c.onBackground)));
                    }

                    final lastGame = snapshot.data ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: c.card,
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
                          style: TextStyle(
                              fontSize: 13, color: c.onBackground),
                        ),
                        subtitle: Text(
                          'Title: ${friend.title}',
                          style: TextStyle(fontSize: 11, color: c.subtle),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'last seen',
                              style:
                                  TextStyle(fontSize: 10, color: c.subtle),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastGame.isNotEmpty
                                  ? DateFormat('dd.MM.yyyy')
                                      .format(lastGame.first.date)
                                  : 'No games',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: c.onBackground,
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

  Future<List<FriendAction>> _buildFriendActions(List<User> friends) async {
    final List<FriendAction> actions = [];
    await Future.wait(friends.map((friend) async {
      final stats =
          await FirestoreService.instance.retrieveUserStatsWithDate(friend);
      if (stats.isNotEmpty) {
        actions.add(FriendAction(
          user: friend,
          type: ActionType.wonGame,
          description: 'recently played a game',
          date: stats.first.date,
        ));
      }
    }));
    actions.sort((a, b) => b.date.compareTo(a.date));
    return actions;
  }

  Widget _buildSocialPage() {
    return FutureBuilder<List<User>>(
      future: _friends,
      builder: (context, friendsSnapshot) {
        if (friendsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = AppColors.of(context);
        if (!friendsSnapshot.hasData || friendsSnapshot.data!.isEmpty) {
          return Center(
            child: Text('No friend activity yet.',
                style: TextStyle(color: c.onBackground)),
          );
        }
        return FutureBuilder<List<FriendAction>>(
          future: _buildFriendActions(friendsSnapshot.data!),
          builder: (context, actionsSnapshot) {
            if (actionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final actions = actionsSnapshot.data ?? [];
            if (actions.isEmpty) {
              return Center(
                child: Text('No recent friend activity.',
                    style: TextStyle(color: c.onBackground)),
              );
            }
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                final bgColor = getActionColor(action.type);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: bgColor,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    leading: _buildCompactFriendAvatar(action.user),
                    title: Text(
                      action.user.username,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    subtitle: Text(
                      action.description,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black87),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Last active',
                            style: TextStyle(
                                fontSize: 10, color: Colors.black54)),
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
          },
        );
      },
    );
  }

  /// Builds the “Leaderboard” page, which includes the user + friends sorted by an attribute.
  Widget _buildRankingPage() {
    return FutureBuilder<List<User>>(
      future: _friendsWithUser,
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
    final c = AppColors.of(context);
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
                  child: user.mapAvatarKeyToAsset().isEmpty
                      ? const Icon(Icons.person, size: 38, color: Colors.white54)
                      : SvgPicture.asset(
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
            style: TextStyle(color: c.onBackground),
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
              TextStyle(color: c.onBackground, fontWeight: FontWeight.bold),
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
    return Builder(
      builder: (context) {
        final c = AppColors.of(context);
        return ListView.builder(
          itemCount: (friends.length - 3).clamp(0, friends.length),
          itemBuilder: (ctx, index) {
            final user = friends[index + 3];
            return ListTile(
              leading: Text('${index + 4}',
                  style: const TextStyle(color: Colors.amber, fontSize: 18)),
              title: Row(
                children: [
                  _buildFriendAvatar(user, radius: 20),
                  const SizedBox(width: 10),
                  Text(user.username, style: TextStyle(color: c.onBackground)),
                ],
              ),
              trailing: Text(
                _selectedAttribute == 'Total Score'
                    ? user.totalScore.toString()
                    : '${(user.winRate * 100).toStringAsFixed(2)}%',
                style: TextStyle(color: c.subtle),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendAvatar(User friend, {double radius = 30}) {
    final assetPath = friend.mapAvatarKeyToAsset();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      child: ClipOval(
        child: assetPath.isEmpty
            ? Icon(Icons.person, size: radius, color: Colors.white54)
            : SvgPicture.asset(
                assetPath,
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

}
