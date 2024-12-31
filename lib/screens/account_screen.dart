import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:provider/provider.dart';
import 'achievements_screen.dart';
import 'personal_statistics_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  User? user;
  IconData? selectedIcon = Icons.person;
  Color? selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    user = userProvider.user;

    if (user != null) {
      selectedIcon = user!.icon;
      selectedColor = user!.iconColor;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: user == null
          ? Center(
              child: ElevatedButton(
                onPressed: () async {
                  userProvider.signIn();
                },
                child: const Text('Sign in with Google'),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildUserCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Achievements"),
                  _buildAchievementsCard(),
                  _buildSectionTitle("Statistics"),
                  _buildStatisticsCard(),
                  _buildSectionTitle("Privacy"),
                  _buildPrivacyCard(),
                  _buildSectionTitle("Dark Mode"),
                  _buildDarkModeCard(),
                  const SizedBox(height: 20),
                  _buildSignOutButton(userProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section with user icon and names
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: selectedColor,
                      child: Icon(
                        selectedIcon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Username',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'dummy data',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _showIconPicker, // Opens the appearance picker
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Right section with SVG image
            SizedBox(
              width: 150,
              height: 150,
              child: SvgPicture.asset(
                'assets/otter_canvas.svg',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(BeerpongIcons.medal, color: Colors.amber),
        title: const Text("Collectables"),
        subtitle: const Text("See what you got"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AchievementsScreen(user: user!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(BeerpongIcons.medal, color: Colors.amber),
        title: const Text("Performance"),
        subtitle: const Text("I see what you did there..."),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalStatisticsScreen(user: user!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.lock, color: Colors.red),
        title: const Text("Privacy"),
        subtitle: const Text("Manage your privacy settings"),
        onTap: () {
          // Privacy settings logic here
        },
      ),
    );
  }

  Widget _buildDarkModeCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SwitchListTile(
        title: const Text("Dark Mode"),
        value: false, // Set this to a variable if needed
        onChanged: (bool value) {
          // Dark mode toggle logic here
        },
      ),
    );
  }

  Widget _buildSignOutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () async {
          userProvider.signOut();
          setState(() {}); // Refresh the UI after signing out
        },
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Icon and Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _iconList.length,
                  itemBuilder: (BuildContext context, int index) {
                    IconData icon = _iconList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIcon = icon;
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          userProvider.updateUser(user!.copyWith(icon: icon));
                        });
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            selectedIcon == icon ? Colors.amber : Colors.grey,
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<IconData> _iconList = [
    BeerpongIcons.bunny_avatar,
    BeerpongIcons.cat_avatar,
    BeerpongIcons.dog_avatar,
    BeerpongIcons.racoon_avatar,
    BeerpongIcons.eagle_avatar,
    BeerpongIcons.frog_avatar,
  ];
}
