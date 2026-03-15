import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Widget _buildTabPageSelector() {
    final List<String> tabs = ['Customize', 'Achievements', 'Activity'];

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

}
