//import 'package:beerpongapp/screens/activity_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:beerpongapp/models/user.dart';
import 'achievements_screen.dart';
import '../profile/custom_user_screen.dart';

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

/// Example account screen refactored to use avatarKey/backgroundKey instead of Icons.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  User? user;

  /// A list of possible avatar keys that map to local assets in your `assets` folder.
  final List<String> _avatarKeys = [
    'avatar_catbeer',
    'avatar_catpants',
    'avatar_cupbeer',
    'avatar_aggroracoon',
    'avatar_frogisland',
    'avatar_cheering',
  ];
  int _currentTabPage = 0;
  late PageController _tabPageController;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentTabPage);
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: user == null
          ? Center(
              child: ElevatedButton(
                onPressed: () async {
                  await userProvider.signIn();
                },
                child: const Text('Sign in with Google'),
              ),
            )
          : Column(
              children: [
                _buildTabPageSelector(),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView(
                    controller: _tabPageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentTabPage = index;
                      });
                    },
                    children: [
                      CustomUserScreen(user: user!),
                      AchievementsScreen(user: user!),
                      _buildSocialPage(),
                      //const ActivityScreen(),
                    ],
                  ),
                ),
              ],
            ),
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

  void _showTitlePicker() {
    final currentUser = user;
    if (currentUser == null) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (currentUser.unlockedTitles.isEmpty) {
      // They have no unlocked titles
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unlocked titles yet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose a Title',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Divider(color: Colors.white70),
              ...currentUser.unlockedTitles.map((titleToGrant) {
                final color = AchievementsScreen.getColorForUnlockedTitle(
                    titleToGrant, currentUser);
                return ListTile(
                  title: Text(
                    titleToGrant,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // Update the user’s active title
                    final updatedUser =
                        currentUser.copyWith(title: titleToGrant);
                    userProvider.updateUser(updatedUser);
                    Navigator.pop(context); // Close the sheet
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Builds the card at the top displaying the user’s avatar and username/title.
  Widget _buildUserCard() {
    final currentUser = user;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Determine which asset to load for the avatar
    final avatarAsset = _mapAvatarKeyToAsset(currentUser.avatarKey);

    return Card(
      color: Colors.transparent, // Transparent background
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            20), // More rounded corners for a credit card look
      ),
      elevation: 5.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image using slanted-gradient.svg
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/slanted-gradient.svg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper part - Winner icons on the left
                  Row(
                    children: [
                      // Winner icons on the left (3 amber icons with circular background)
                      Row(
                        children: List.generate(3, (index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // Space to push content down
                  // Bottom part - User data on the left and CircleAvatar on the right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - User text and username at the bottom-left
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showTitlePicker(),
                            child: Text(
                              currentUser.title.isNotEmpty
                                  ? currentUser.title
                                  : 'No Title Yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: currentUser.title.isNotEmpty
                                    ? AchievementsScreen
                                        .getColorForUnlockedTitle(
                                            currentUser.title, currentUser)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Right side - CircleAvatar with either icon or SVG background
                      GestureDetector(
                        onTap: _showAvatarPicker, // Trigger the icon picker
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Display an icon or SVG based on selectedAvatar
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
                              child: avatarAsset.isNotEmpty
                                  ? ClipOval(
                                      child: SvgPicture.asset(
                                        avatarAsset,
                                        fit: BoxFit.cover,
                                        width: 56,
                                        height: 56,
                                        placeholderBuilder:
                                            (BuildContext context) => Container(
                                          color: Colors.grey,
                                          child: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPageSelector() {
    final List<String> tabs = ["Customize", "Achievements", "Activity"];

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
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTabPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (_currentTabPage != index) {
                    setState(() {
                      _currentTabPage = index;
                    });
                    _tabPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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

  /// Displays a sign out button at the bottom.
  Widget _buildSignOutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onPressed: () async {
          await userProvider.signOut();
          setState(() {}); // Refresh UI
        },
        child: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Opens a bottom sheet where the user can pick an avatarKey from a predefined list.
  void _showAvatarPicker() {
    final currentUser = user;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black87,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select an Avatar',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Adjust as you like
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _avatarKeys.length,
                  itemBuilder: (BuildContext context, int index) {
                    final key = _avatarKeys[index];
                    final assetPath = _mapAvatarKeyToAsset(key);
                    final isSelected = (currentUser.avatarKey == key);

                    return GestureDetector(
                      onTap: () {
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        final updatedUser =
                            currentUser.copyWith(avatarKey: key);
                        userProvider.updateUser(updatedUser);
                        Navigator.pop(context); // Close the bottom sheet
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: Colors.amber, width: 3)
                              : Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: assetPath.isNotEmpty
                            ? SvgPicture.asset(assetPath, fit: BoxFit.cover)
                            : const Icon(Icons.person, color: Colors.white),
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

  /// Maps a given avatarKey to the actual local asset path.
  /// For example: 'bunny' -> 'assets/avatars/bunny.png'
  String _mapAvatarKeyToAsset(String avatarKey) {
    if (avatarKey.isEmpty) return '';
    // Adjust as needed for your file naming structure
    return 'assets/avatars/$avatarKey.svg';
  }
}
