import 'package:beerpongapp/screens/activity_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:beerpongapp/models/user.dart';
import 'achievements_screen.dart';
import 'personal_statistics_screen.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.black,
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
                const SizedBox(height: 20),
                _buildUserCard(),
                const SizedBox(height: 10),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PersonalStatisticsScreen(user: user!),
                      AchievementsScreen(user: user!),
                      const ActivityScreen(),
                    ],
                  ),
                ),
              ],
            ),
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
                final color =
                    AchievementsScreen.getColorForUnlockedTitle(titleToGrant, currentUser);
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
                                    ? AchievementsScreen.getColorForUnlockedTitle(
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

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white70,
      tabs: const [
        Tab(icon: Icon(Icons.pie_chart), text: "Stats"),
        Tab(icon: Icon(Icons.emoji_events), text: "Achievements"),
        Tab(icon: Icon(Icons.history), text: "Activity"),
      ],
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
