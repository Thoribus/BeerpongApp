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
            const CircleAvatar(
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
        'stages': [0, 25, 50, 100], // Bronze, Silver, Amber, Violet
      },
      {
        'icon': Icons.star_border,
        'title': 'Losses',
        'currentProgress': user.losses,
        'stages': [0, 25, 50, 100],
      },
      {
        'icon': Icons.thumb_up,
        'title': 'Friendships',
        'currentProgress': 10,
        'stages': [0, 5, 15, 20],
      },
      {
        'icon': Icons.podcasts,
        'title': 'Tournaments',
        'currentProgress': 5,
        'stages': [0, 3, 7, 10],
      },
      {
        'icon': Icons.games,
        'title': 'Games Played',
        'currentProgress': 30,
        'stages': [0, 25, 50, 100],
      },
      {
        'icon': Icons.fire_truck,
        'title': 'Streaks',
        'currentProgress': 15,
        'stages': [0, 10, 20, 30],
      },
      {
        'icon': Icons.access_time,
        'title': 'Hours Played',
        'currentProgress': 21,
        'stages': [0, 20, 40, 60],
      },
      {
        'icon': Icons.badge,
        'title': 'Badges Earned',
        'currentProgress': 4,
        'stages': [0, 5, 10, 15],
      },
      {
        'icon': Icons.military_tech,
        'title': 'Challenges',
        'currentProgress': 12,
        'stages': [0, 5, 15, 25],
      },
      {
        'icon': Icons.leaderboard,
        'title': 'Rankings',
        'currentProgress': 3,
        'stages': [0, 2, 4, 5],
      },
      {
        'icon': Icons.group,
        'title': 'Team Wins',
        'currentProgress': 18,
        'stages': [0, 10, 20, 30],
      },
      {
        'icon': Icons.school,
        'title': 'Training Sessions',
        'currentProgress': 9,
        'stages': [0, 5, 10, 15],
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
          stages: achievements[index]['stages'] as List<int>,
        );
      },
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int currentProgress,
    required List<int> stages,
  }) {
    // Ensure the stages list is not empty or invalid
    if (stages.isEmpty) {
      return const SizedBox(); // Avoid rendering a card if stages are empty
    }

    // Get the current stage index
    int stageIndex = _getCurrentStageIndex(currentProgress, stages);
    // Ensure valid stage index
    if (stageIndex < 0 || stageIndex >= stages.length) {
      stageIndex = 0; // Default to the first stage if index is invalid
    }

    // If the current progress is 0, use grey for the first stage
    Color stageColor = (currentProgress == 0 || currentProgress < stages[1])
        ? Colors.grey // Grey color for no achievement
        : _getStageColor(stageIndex);

    // Scale the progress based on the current stage's max value
    double progressPercentage =
        (currentProgress / stages[stageIndex]).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        _showAchievementDialog(context, title, currentProgress, stages);
      },
      child: Card(
        elevation: 4,
        color: stageColor.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed icon size and dynamic color
              Icon(icon, size: 50, color: stageColor),
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
              // Progress Bar with dynamic color
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(stageColor),
              ),
              const SizedBox(height: 2),
              // Completion Text
              Text(
                '$currentProgress / ${stages[stageIndex + 1]}',
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

  int _getCurrentStageIndex(int currentProgress, List<int> stages) {
    // Return the current stage index based on progress
    for (int i = stages.length - 1; i >= 0; i--) {
      if (currentProgress >= stages[i]) {
        return i;
      }
    }
    return 0; // Default to first stage
  }

  Color _getStageColor(int stageIndex) {
    // Return the appropriate color for the stage
    switch (stageIndex) {
      case 3:
        return Colors.purple; // Violet
      case 2:
        return Colors.amber; // Amber
      case 1:
        return Colors.blueGrey; // Silver
      default:
        return Colors.brown; // Bronze
    }
  }

  void _showAchievementDialog(BuildContext context, String title,
      int currentProgress, List<int> stages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
              'You have completed $currentProgress out of ${stages.last} for this achievement.\nCurrent stage: ${_getStageName(currentProgress, stages)}'),
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

  String _getStageName(int currentProgress, List<int> stages) {
    // Return the name of the current stage
    int stageIndex = _getCurrentStageIndex(currentProgress, stages);
    switch (stageIndex) {
      case 3:
        return 'Violet';
      case 2:
        return 'Amber';
      case 1:
        return 'Silver';
      default:
        return 'Bronze';
    }
  }
}
