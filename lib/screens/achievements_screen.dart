import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';

class AchievementsScreen extends StatelessWidget {
  final User user;

  const AchievementsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildAchievement(
            icon: Icons.star,
            title: 'Wins',
            currentProgress: user.wins,
            totalProgress: 50,
          ),
          _buildAchievement(
            icon: Icons.star_border,
            title: 'Losses',
            currentProgress: user.losses,
            totalProgress: 50,
          ),
          // Add more achievements here as needed
        ],
      ),
    );
  }

  Widget _buildAchievement({
    required IconData icon,
    required String title,
    required int currentProgress,
    required int totalProgress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: currentProgress / totalProgress,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
        SizedBox(height: 8),
        Text(
          '$currentProgress / $totalProgress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
