import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/screens/profile/feedback_sheet.dart';
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
    final isSupporter = userProvider.user?.isSupporter ?? false;
    return ColoredBox(
      color: c.appBar,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    context.loc.accountProfile,
                    style: TextStyle(
                      color: c.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSupporter) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            context.loc.accountSupporter,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.feedback_outlined,
                color: c.onBackground, size: 20),
            tooltip: context.loc.accountFeedbackTooltip,
            onPressed: () {
              final user = userProvider.user;
              if (user != null) FeedbackSheet.show(context, user);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: c.onBackground, size: 20),
            tooltip: context.loc.accountSignOutTooltip,
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
        title: Text(context.loc.accountSignOutTitle),
        content: Text(context.loc.accountSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.loc.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.loc.accountSignOutConfirm,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await userProvider.signOut();
    }
  }
}
