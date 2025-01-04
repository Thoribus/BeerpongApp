import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:beerpongapp/models/user.dart';
import 'achievements_screen.dart';
import 'personal_statistics_screen.dart';

/// Example account screen refactored to use avatarKey/backgroundKey instead of Icons.
class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  User? user;

  /// A list of possible avatar keys that map to local assets in your `assets` folder.
  final List<String> _avatarKeys = [
    'bunny',
    'cat',
    'dog',
    'raccoon',
    'eagle',
    'frog',
  ];

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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildUserCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Achievements"),
                  _buildAchievementsCard(),
                  _buildSectionTitle("Statistics"),
                  _buildStatisticsCard(),
                  _buildSectionTitle("Privacy"),
                  _buildPrivacyCard(),
                  _buildSectionTitle("Dark Mode"),
                  _buildDarkModeCard(),
                  const SizedBox(height: 20),
                  _buildSignOutButton(userProvider),
                ],
              ),
            ),
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
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section: avatar image + user info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Circular avatar image
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: avatarAsset.isNotEmpty
                          ? ClipOval(
                              child: Image.asset(
                                avatarAsset,
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Username & Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          currentUser.title.isNotEmpty
                              ? currentUser.title
                              : 'No Title Yet',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _showAvatarPicker, // Let user pick a new avatar
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Change Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Right section with an SVG image (example decorative image)
            SizedBox(
              width: 150,
              height: 150,
              child: SvgPicture.asset(
                'assets/otter_canvas.svg', // adjust path if needed
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a section title with bold text.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// A card leading to AchievementsScreen.
  Widget _buildAchievementsCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: const Text("Collectables", style: TextStyle(color: Colors.white)),
        subtitle: const Text("See what you got", style: TextStyle(color: Colors.white70)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AchievementsScreen(user: user!),
            ),
          );
        },
      ),
    );
  }

  /// A card leading to the PersonalStatisticsScreen.
  Widget _buildStatisticsCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.pie_chart, color: Colors.amber),
        title: const Text("Performance", style: TextStyle(color: Colors.white)),
        subtitle: const Text("I see what you did there...", style: TextStyle(color: Colors.white70)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalStatisticsScreen(user: user!),
            ),
          );
        },
      ),
    );
  }

  /// Placeholder for privacy settings.
  Widget _buildPrivacyCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const ListTile(
        leading: Icon(Icons.lock, color: Colors.red),
        title: Text("Privacy", style: TextStyle(color: Colors.white)),
        subtitle: Text("Manage your privacy settings", style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  /// Dark Mode toggle placeholder card.
  Widget _buildDarkModeCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SwitchListTile(
        title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
        value: false, // TODO: Implement a real dark-mode toggle
        onChanged: (bool value) {
          // Toggle logic here, e.g. using a theme provider
        },
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        final updatedUser = currentUser.copyWith(avatarKey: key);
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
                            ? Image.asset(assetPath, fit: BoxFit.cover)
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
    return 'assets/avatars/$avatarKey.png';
  }
}
