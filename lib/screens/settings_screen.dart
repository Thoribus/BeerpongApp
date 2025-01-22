import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  User? currentUser;
  double _progress = 0.0;
  Timer? _timer;

  void _startProgressBar() {
    setState(() {
      _progress = 0.0;
    });

    const duration =
        Duration(milliseconds: 16); // High-frequency updates (60 FPS)
    _timer?.cancel();
    _timer = Timer.periodic(duration, (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 1 /
              (10 * 60); // Smoothly increment progress over 30 seconds (60 FPS)
          _progress =
              _progress.clamp(0.0, 1.0); // Ensure progress stays within bounds
        } else {
          _timer?.cancel();
          _progress = 1.0; // Finalize the progress at 100%
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
                  _buildBattleSection(), // New section for "Create battle" UI
                ],
              ),
            ),
    );
  }

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

  Widget _buildDarkModeCard() {
    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SwitchListTile(
        title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
        value:
            false, // Replace with an actual variable if you implement theme switching
        onChanged: (bool value) {
          // TODO: Implement dark mode toggle logic here
        },
      ),
    );
  }

  Widget _buildBattleSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BEERPONG BATTLE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              DropdownButton<String>(
                dropdownColor: Colors.grey[900],
                value: "Popular",
                items: const [
                  DropdownMenuItem(
                    value: "Popular",
                    child:
                        Text("Popular", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: "Newest",
                    child:
                        Text("Newest", style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) {
                  // TODO: Handle sorting logic here
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {
              _startProgressBar(); // Start progress bar animation on button click
              // TODO: Add create battle logic
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Create game"),
          ),
          const SizedBox(height: 20),
          _buildProgressBar(), // Add progress bar here
          const SizedBox(height: 20),
          Card(
            color: Colors.grey[900],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("ROUND 5",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("2 VS 2",
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_border_outlined, color: Colors.amber),
                          Icon(Icons.star_border_outlined, color: Colors.green),
                          Icon(Icons.star_border_outlined, color: Colors.blue),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPlayerAvatar(1, Colors.purple),
                      const Text(" VS ", style: TextStyle(color: Colors.white)),
                      _buildPlayerAvatar(9, Colors.green),
                      _buildEmptyAvatar(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50, // Same height as the button
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            stops: [_progress, _progress + 0.01],
                            colors: [
                              Colors
                                  .grey, // Gradually appears as progress increases
                              Colors.amber,
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .transparent, // Transparent to show the gradient
                          shadowColor:
                              Colors.transparent, // Removes button shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Join battle logic
                        },
                        child: const Text(
                          "You got 30s to join. Hurry up!",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _progress,
      backgroundColor: Colors.grey[800],
      color: Colors.amberAccent,
      minHeight: 6,
    );
  }

  Widget _buildPlayerAvatar(int number, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: Text(
          number.toString(),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.add, color: Colors.white70),
      ),
    );
  }
}
