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

class BaseScreenState extends State<BaseScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex = widget.selectedIndex;
  late PageController _pageController;

  // For the animated top line indicator
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F11),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left-aligned title
                  Text(
                    _getAppBarTitle(_selectedIndex),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),

                  // Icons
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: Colors.white,
                    onPressed: () {
                      // TODO: Notification action
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: Colors.white,
                    onPressed: () {
                      // TODO: Settings action
                    },
                  ),

                  // User Info
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PlayerOne',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
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
        height: 76, // slightly smaller height
        decoration: BoxDecoration(
          color: const Color(0xFF131417),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / 5; // 🔄 dynamic width
            final indicatorWidth = 42.0;
            final indicatorLeft =
                _selectedIndex * itemWidth + (itemWidth - indicatorWidth) / 2;

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                // Top indicator
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

                // Navigation items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.settings_outlined, 'Settings', 0),
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
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) => [
        'Settings',
        'Friends',
        'Beerpong Companion',
        'Statistics',
        'Profile',
      ][index];
}
