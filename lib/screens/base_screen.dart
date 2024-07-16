import 'package:flutter/material.dart';
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

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

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
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to change pages
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          FriendsListScreen(),
          HomeScreen(),
          StatisticsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, color: _getIconColor(0)),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline, color: _getIconColor(1)),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_bar_outlined, color: _getIconColor(2)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined, color: _getIconColor(3)),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, color: _getIconColor(4)),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFF0AE1D),
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }

  Color _getIconColor(int index) {
    return _selectedIndex == index ? const Color(0xFFF0AE1D) : Colors.grey;
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Settings';
      case 1:
        return 'Friendlist';
      case 2:
        return '';
      case 3:
        return 'Statistics';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
