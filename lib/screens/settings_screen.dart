import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  User? currentUser;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    currentUser = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.black,
      body: currentUser == null
          ? _buildSignInPrompt(userProvider)
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

  /// Builds a simple sign-in prompt if no user is logged in.
  Widget _buildSignInPrompt(UserProvider userProvider) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await userProvider.signIn();
        },
        child: const Text('Sign in with Google'),
      ),
    );
  }

  /// Builds a labeled section title with bold styling.
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

  /// A placeholder card for managing privacy.
  Widget _buildPrivacyCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.lock, color: Colors.red),
        title: const Text(
          "Privacy",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          "Manage your privacy settings",
          style: TextStyle(color: Colors.white70),
        ),
        onTap: () {
          // TODO: Implement privacy settings logic here
        },
      ),
    );
  }

  /// A placeholder card for toggling dark mode.
  Widget _buildDarkModeCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SwitchListTile(
        title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
        value: false, // Replace with an actual variable if you implement theme switching
        onChanged: (bool value) {
          // TODO: Implement dark mode toggle logic here
        },
      ),
    );
  }
}
