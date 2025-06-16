import 'package:flutter/material.dart';
import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/screens/home_screen.dart';
import 'package:beerpongapp/screens/settings_screen.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';

class BaseScreen extends StatefulWidget {
  final int selectedIndex;
  const BaseScreen({required this.selectedIndex, super.key});

  @override
  BaseScreenState createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen> {
  late int _selectedIndex = widget.selectedIndex;
  late PageController _pageController;

  bool isDarkMode = true;
  String language = 'en'; // 'en' or 'de'

  final double _itemWidth = 78;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _openSettingsDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F11),
      drawer: Drawer(
        backgroundColor:
            isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED),
        child: ListView(
          padding: EdgeInsets.zero,
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
                    child: Icon(Icons.person, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peppa Wutz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@wutzi',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🌗 Dark Mode Toggle
            SwitchListTile(
              title: Text(
                language == 'en' ? 'Dark Mode' : 'Dunkelmodus',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              value: isDarkMode,
              onChanged: (value) => setState(() => isDarkMode = value),
              secondary: Icon(
                Icons.dark_mode,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            // 🌐 Language Toggle
            SwitchListTile(
              title: Text(
                language == 'en' ? 'Language: English' : 'Sprache: Deutsch',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              value: language == 'en',
              onChanged: (value) =>
                  setState(() => language = value ? 'en' : 'de'),
              secondary: Icon(
                Icons.language,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            // Optional: Add more drawer items here
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined,
                  color: isDarkMode ? Colors.white : Colors.black),
              title: Text(
                language == 'en'
                    ? 'Privacy Settings'
                    : 'Datenschutzeinstellungen',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              onTap: () {
                // Navigate to privacy settings screen (optional)
              },
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF151924),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
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
                        _getAppBarTitle(_selectedIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: Colors.white,
                    onPressed: () {
                      // TODO: Notification action
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          SettingsScreen(),
          FriendsListScreen(),
          HomeScreen(),
          StatisticsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF131417),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5;
            final indicatorWidth = 42.0;
            final indicatorLeft =
                _selectedIndex * itemWidth + (itemWidth - indicatorWidth) / 2;

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
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.shopping_bag_outlined, 'Shop', 0),
                    _buildNavItem(Icons.favorite_outline, 'Friends', 1),
                    _buildNavItem(Icons.sports_bar_outlined, 'Home', 2),
                    _buildNavItem(Icons.bar_chart_outlined, 'Stats', 3),
                    _buildNavItem(Icons.account_circle_outlined, 'Profile', 4),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppConstants.primaryColor : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: _itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22), // Smaller icon
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

  Widget _buildSettingsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1D28),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF0E0F11),
            ),
            child: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          _buildDrawerItem(Icons.dark_mode, 'Dark Mode', () {}),
          _buildDrawerItem(Icons.lock_outline, 'Privacy Settings', () {}),
          _buildDrawerItem(Icons.language, 'Language', () {}),
          _buildDrawerItem(Icons.info_outline, 'About', () {}),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  String _getAppBarTitle(int index) => [
        'Shop',
        'Friends',
        'Beerpong Companion',
        'Statistics',
        'Profile',
      ][index];
}
