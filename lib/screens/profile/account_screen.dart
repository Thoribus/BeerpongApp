import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/custom_user_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final User? user = userProvider.user;
    final c = AppColors.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          _buildHeader(context, userProvider, c),
          Expanded(child: CustomUserScreen(user: user)),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, UserProvider userProvider, AppColors c) {
    return ColoredBox(
      color: Colors.grey.shade800,
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            tooltip: 'Sign out',
            onPressed: () => _confirmSignOut(context, userProvider),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, UserProvider userProvider) async {
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
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await userProvider.signOut();
    }
  }
}
