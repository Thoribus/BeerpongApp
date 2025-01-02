import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/settings_screen.dart';
import 'package:beerpongapp/constants.dart'; // Use centralized constants
import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/screens/home_screen.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';

class BaseScreen extends StatefulWidget {
  final int selectedIndex;

  const BaseScreen({required this.selectedIndex, super.key});

  @override
  BaseScreenState createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen> {
  late PageController _pageController;
  late int _selectedIndex = widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) => _pageController.jumpToPage(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF0AE1D),
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.secondaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to change pages
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          SettingsScreen(),
          FriendsListScreen(),
          HomeScreen(),
          StatisticsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppConstants.secondaryColor,
        type: BottomNavigationBarType.fixed,
        items: [
          _createNavBarItem(Icons.settings_outlined, 'Settings', 0),
          _createNavBarItem(Icons.favorite_outline, 'Friends', 1),
          _createNavBarItem(Icons.sports_bar_outlined, 'Home', 2),
          _createNavBarItem(Icons.bar_chart_outlined, 'Stats', 3),
          _createNavBarItem(Icons.account_circle_outlined, 'Profile', 4),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppConstants.primaryColor,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }

  String _getAppBarTitle(int index) => [
        'Settings',
        'Friends',
        '',
        'Statistics',
        'Profile'
      ][index];

  BottomNavigationBarItem _createNavBarItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(icon, color: _selectedIndex == index ? AppConstants.primaryColor : Colors.grey),
      label: label,
    );
  }
}