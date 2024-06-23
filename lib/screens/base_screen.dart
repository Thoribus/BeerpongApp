import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/screens/home_screen.dart';

class BaseScreen extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const BaseScreen({required this.child, required this.selectedIndex, Key? key})
      : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Prevents the back button from appearing
        backgroundColor: Colors.amber, // Amber background color for app bar
        title: Text(
          _getAppBarTitle(widget.selectedIndex),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Text color of the app bar title
          ),
        ),
        centerTitle: true, // Center align the title
      ),
      body: widget.child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // Override the bottom navigation bar theme
          canvasColor:
              Colors.black, // Background color of the BottomNavigationBar
          primaryColor:
              Colors.amber, // Active color of the BottomNavigationBar icons
          textTheme: Theme.of(context).textTheme.copyWith(
                caption: TextStyle(
                    color: Colors
                        .grey), // Inactive color of the BottomNavigationBar icons
              ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black, // Setting background color to black
          type:
              BottomNavigationBarType.fixed, // Ensures all items are fixed size
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
              icon:
                  Icon(Icons.account_circle_outlined, color: _getIconColor(4)),
              label: 'Profile',
            ),
          ],
          currentIndex: widget.selectedIndex,
          selectedItemColor: Colors.amber,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  Color _getIconColor(int index) {
    return widget.selectedIndex == index ? Colors.amber : Colors.grey;
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Settings';
      case 1:
        return 'Friendlist';
      case 2:
        return 'Beerpong!';
      case 3:
        return 'Statistics';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }

  void _onItemTapped(int index) {
    if (index != widget.selectedIndex) {
      switch (index) {
        case 0:
          // Placeholder for the Settings screen
          print("Settings screen tapped");
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/friendlist');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/'); // Home screen
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/statistics');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/account');
          break;
      }
    }
  }
}
