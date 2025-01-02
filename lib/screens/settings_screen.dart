import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
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
}
