import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:provider/provider.dart';
import 'achievements_screen.dart';
import 'personal_statistics_screen.dart';

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
                  _buildSectionTitle("Appearance"),
                  _buildAppearanceCard(),
                  _buildSectionTitle("Achievements"),
                  _buildAchievementsCard(),
                  _buildSectionTitle("Statistics"),
                  _buildStatisticsCard(),
                  _buildSectionTitle("Privacy"),
                  _buildPrivacyCard(),
                  _buildSectionTitle("Dark Mode"),
                  _buildDarkModeCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showIconPicker,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: selectedColor,
                    child: Icon(
                      selectedIcon,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  user!.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Text(
              "User ID: ${user!.id}",
              style: const TextStyle(color: Colors.white70),
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

  Widget _buildAppearanceCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.palette, color: Colors.amber),
        title: const Text("Customize"),
        subtitle: const Text("Make the app your own"),
        onTap: _showIconPicker,
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
