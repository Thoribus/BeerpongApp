import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:beerpongapp/models/user.dart';
import 'achievements_screen.dart';
import '../profile/custom_user_screen.dart';
import '../../widgets/app_tab_bar.dart';

/// Example account screen refactored to use avatarKey/backgroundKey instead of Icons.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  User? user;
  Future<List<User>>? _friendsFuture;

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
                _buildTabBarWithLogout(userProvider),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView(
                    controller: _tabPageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentTabPage = index;
                        // Lazy-load friends only when the Social tab is first opened.
                        if (index == 2 && _friendsFuture == null && user != null) {
                          _friendsFuture =
                              FirestoreService.instance.getFriends(user!.id);
                        }
                      });
                    },
                    children: [
                      CustomUserScreen(user: user!),
                      AchievementsScreen(user: user!),
                      _buildSocialPage(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSocialPage() {
    return FutureBuilder<List<User>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(
            child: Text('No friends yet. Add some friends to see their activity!'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final totalGames = friend.wins + friend.losses;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.greenAccent.shade100,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: Text(
                    friend.username.isNotEmpty ? friend.username[0] : '?',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                title: Text(
                  friend.username,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
                subtitle: Text(
                  '${friend.wins} wins · ${friend.losses} losses · $totalGames games played',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBarWithLogout(UserProvider userProvider) {
    return ColoredBox(
      color: Colors.grey.shade800,
      child: Row(
        children: [
          Expanded(
            child: AppTabBar(
              tabs: const ['Customize', 'Achievements', 'Activity'],
              selectedIndex: _currentTabPage,
              onTabSelected: (index) {
                if (_currentTabPage != index) {
                  setState(() => _currentTabPage = index);
                }
              },
              pageController: _tabPageController,
              backgroundColor: Colors.grey.shade800,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            tooltip: 'Sign out',
            onPressed: () => _confirmSignOut(userProvider),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(UserProvider userProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await userProvider.signOut();
    }
  }

}
