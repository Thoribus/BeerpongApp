import 'package:flutter/material.dart';
import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/models/invitation.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/locale_provider.dart';
import 'package:beerpongapp/util/theme_provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/widgets/user_card.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BaseScreen extends StatefulWidget {
  final StatefulNavigationShell shell;
  const BaseScreen({required this.shell, super.key});

  @override
  BaseScreenState createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen> {
  void _onItemTapped(int index) {
    widget.shell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = userProvider.user;
    final isDarkMode = themeProvider.isDarkMode;
    final currentLang = localeProvider.locale.languageCode;
    final selectedIndex = widget.shell.currentIndex;
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      drawer: Drawer(
        backgroundColor:
            isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // === Top Section: Header + UserCard ===
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: c.drawerHeader,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: c.border,
                            child: Icon(Icons.person,
                                size: 28, color: c.onBackground),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? 'Peppa Wutz',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: c.onBackground,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@${user?.username ?? 'guest'}',
                                  style: TextStyle(
                                    color: c.subtle,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: UserCard(
                          user: user,
                          onTitleTap: () {},
                          onAvatarTap: () {},
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // === Bottom Section: Settings Toggles ===
            Column(
              children: [
                Divider(color: c.divider),
                SwitchListTile(
                  title: Text(
                    context.loc.settingsDarkMode,
                    style: TextStyle(color: c.onBackground),
                  ),
                  value: isDarkMode,
                  onChanged: (_) => themeProvider.toggle(),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: c.onBackground,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.language, color: c.onBackground),
                  title: Text(
                    context.loc.settingsLanguage,
                    style: TextStyle(color: c.onBackground),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _langChip(context, 'EN', currentLang == 'en', c,
                          () => localeProvider.setLocale(const Locale('en'))),
                      const SizedBox(width: 6),
                      _langChip(context, 'DE', currentLang == 'de', c,
                          () => localeProvider.setLocale(const Locale('de'))),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: c.onBackground),
                  title: Text(
                    context.loc.settingsPrivacy,
                    style: TextStyle(color: c.onBackground),
                  ),
                  onTap: () {
                    // Optional: navigate to privacy settings
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            color: c.appBar,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.settings, color: c.onBackground),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getAppBarTitle(selectedIndex, context),
                        style: TextStyle(
                          color: c.onBackground,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (user != null)
                    StreamBuilder<List<Invitation>>(
                      stream: FirestoreService.instance
                          .pendingInvitationsStream(user.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: Icon(
                                count > 0
                                    ? Icons.notifications
                                    : Icons.notifications_none,
                                color: c.onBackground,
                              ),
                              onPressed: () =>
                                  context.push(AppRoutes.invitations),
                            ),
                            if (count > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 9 ? '9+' : '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else
                    Icon(Icons.notifications_none, color: c.onBackground),
                ],
              ),
            ),
          ),
        ),
      ),
      body: widget.shell,
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: c.navBar,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5;
            const indicatorWidth = 42.0;
            final indicatorLeft =
                selectedIndex * itemWidth + (itemWidth - indicatorWidth) / 2;

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0,
                  left: indicatorLeft,
                  child: Container(
                    width: indicatorWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.shopping_bag_outlined, context.loc.navShop, 0, selectedIndex),
                    _buildNavItem(Icons.favorite_outline, context.loc.navFriends, 1, selectedIndex),
                    _buildNavItem(Icons.sports_bar_outlined, context.loc.navHome, 2, selectedIndex),
                    _buildNavItem(Icons.workspaces_outlined, context.loc.navGames, 3, selectedIndex),
                    _buildNavItem(Icons.account_circle_outlined, context.loc.navProfile, 4, selectedIndex),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? Colors.orange : AppColors.of(context).subtle;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langChip(BuildContext context, String label, bool selected,
      AppColors c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.orange : c.subtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : c.subtle,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index, BuildContext context) => [
        context.loc.navShop,
        context.loc.navFriends,
        context.loc.appTitle,
        context.loc.navGames,
        context.loc.navProfile,
      ][index];
}
