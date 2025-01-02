import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';

class AchievementsScreen extends StatelessWidget {
  final User user;

  const AchievementsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(),
          const SizedBox(height: 16),
          _buildAchievementsGrid(context),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    double progressPercentage =
        (user.wins / 50).clamp(0.0, 1.0); // Assuming 50 is the total

    return Card(
      color: Colors.amber.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.amber,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.wins} / 50 Achievements Completed',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    final achievements = [
      {
        'icon': Icons.star,
        'title': 'Wins',
        'currentProgress': user.wins,
        'totalProgress': 50,
      },
      {
        'icon': Icons.star_border,
        'title': 'Losses',
        'currentProgress': user.losses,
        'totalProgress': 50,
      },
      {
        'icon': Icons.thumb_up,
        'title': 'Friendships',
        'currentProgress': 10,
        'totalProgress': 20,
      },
      {
        'icon': Icons.podcasts,
        'title': 'Tournaments',
        'currentProgress': 5,
        'totalProgress': 10,
      },
      {
        'icon': Icons.games,
        'title': 'Games Played',
        'currentProgress': 30,
        'totalProgress': 100,
      },
      {
        'icon': Icons.fire_truck,
        'title': 'Streaks',
        'currentProgress': 15,
        'totalProgress': 30,
      },
      {
        'icon': Icons.access_time,
        'title': 'Hours Played',
        'currentProgress': 20,
        'totalProgress': 50,
      },
      {
        'icon': Icons.badge,
        'title': 'Badges Earned',
        'currentProgress': 8,
        'totalProgress': 15,
      },
      {
        'icon': Icons.military_tech,
        'title': 'Challenges',
        'currentProgress': 12,
        'totalProgress': 25,
      },
      {
        'icon': Icons.leaderboard,
        'title': 'Rankings',
        'currentProgress': 3,
        'totalProgress': 5,
      },
      {
        'icon': Icons.group,
        'title': 'Team Wins',
        'currentProgress': 18,
        'totalProgress': 30,
      },
      {
        'icon': Icons.school,
        'title': 'Training Sessions',
        'currentProgress': 9,
        'totalProgress': 15,
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75, // Adjust aspect ratio to make the cards taller
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      physics:
          const NeverScrollableScrollPhysics(), // Prevent scrolling on the grid
      shrinkWrap: true,
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(
          context,
          icon: achievements[index]['icon'] as IconData,
          title: achievements[index]['title'] as String,
          currentProgress: achievements[index]['currentProgress'] as int,
          totalProgress: achievements[index]['totalProgress'] as int,
        );
      },
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int currentProgress,
    required int totalProgress,
  }) {
    return GestureDetector(
      onTap: () {
        _showAchievementDialog(context, title, currentProgress, totalProgress);
      },
      child: Card(
        elevation: 4,
        color: Colors.amber.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed icon size
              Icon(icon, size: 50, color: Colors.amber),
              const SizedBox(height: 8),
              // Title with automatic size adjustment
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis, // Prevent overflow
                maxLines: 1, // Limit to one line
              ),
              const SizedBox(height: 8),
              // Progress Bar
              LinearProgressIndicator(
                value: currentProgress / totalProgress,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 2),
              // Completion Text
              Text(
                '$currentProgress / $totalProgress',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDialog(BuildContext context, String title,
      int currentProgress, int totalProgress) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
              'You have completed $currentProgress out of $totalProgress for this achievement.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
