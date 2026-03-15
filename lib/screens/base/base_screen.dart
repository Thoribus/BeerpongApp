import 'package:flutter/material.dart';
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
    final user = userProvider.user;
    final isDarkMode = themeProvider.isDarkMode;
    final selectedIndex = widget.shell.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F11),
      drawer: Drawer(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED),
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
                        color: isDarkMode
                            ? const Color(0xFF2C2F36)
                            : const Color(0xFFDCDCDC),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? 'Peppa Wutz',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@wutzi',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
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
                const Divider(color: Colors.grey),
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: isDarkMode,
                  onChanged: (_) => themeProvider.toggle(),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: isDarkMode ? Colors.white : Colors.black),
                  title: Text(
                    'Privacy Settings',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
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
            color: Colors.grey.shade800,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _getAppBarTitle(selectedIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: Colors.white,
                    onPressed: () {
                      // Push notifications: not yet implemented
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: widget.shell,
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFF131417),
          borderRadius: BorderRadius.only(
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
                    _buildNavItem(Icons.shopping_bag_outlined, 'Shop', 0, selectedIndex),
                    _buildNavItem(Icons.favorite_outline, 'Friends', 1, selectedIndex),
                    _buildNavItem(Icons.sports_bar_outlined, 'Home', 2, selectedIndex),
                    _buildNavItem(Icons.workspaces_outlined, 'Games', 3, selectedIndex),
                    _buildNavItem(Icons.account_circle_outlined, 'Profile', 4, selectedIndex),
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
    final color = isSelected ? Colors.orange : Colors.grey.shade500;

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

  String _getAppBarTitle(int index) => [
        'Shop',
        'Friends',
        'Beerpong Companion',
        'Games',
        'Profile',
      ][index];
}
