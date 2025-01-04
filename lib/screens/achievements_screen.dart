import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<TextButton> actions;
  final String? imagePath;
  final Color stageColor; // Color for the current stage
  final int stageProgress; // Current progress for the stage

  const CustomDialog({
    required this.title,
    required this.description,
    required this.actions,
    this.imagePath,
    required this.stageColor,
    required this.stageProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 24.0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          image: DecorationImage(
            image: AssetImage("assets/background_achievement.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: _renderDialogContent(context),
      ),
    );
  }

  Widget _renderDialogContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 100),
        if (imagePath != null) _renderImageWithBorder(imagePath!, context),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _renderImageWithBorder(String imagePath, BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: stageColor, // Stage color for border
              width: 8.0, // Bold border width
            ),
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: AssetImage("assets/$imagePath"),
              fit: BoxFit.scaleDown,
            ),
          ),
          width: 130,
          height: 130,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.red, // Notification bubble color
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white, // Optional white border around the bubble
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                "$stageProgress", // Display progress
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                Icons.one_k,
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
        'imagePath': "ach_wins.png",
        'title': 'Wins',
        'currentProgress': user.wins,
        'stages': [0, 25, 50, 100], // Bronze, Silver, Amber, Violet
      },
      {
        'imagePath': "ach_lost.png",
        'title': 'Losses',
        'currentProgress': user.losses,
        'stages': [0, 25, 50, 100],
      },
      {
        'imagePath': "ach_friends.png",
        'title': 'Friendships',
        'currentProgress': 10,
        'stages': [0, 5, 15, 20],
      },
      {
        'imagePath': "ach_champion.png",
        'title': 'Champion',
        'currentProgress': user.totalScore.round(),
        'stages': [0, 20, 100, 1000],
      },
      {
        'imagePath': "ach_loses.png",
        'title': 'Misses',
        'currentProgress': user.totalMisses,
        'stages': [0, 25, 50, 1000],
      },
      {
        'imagePath': "ach_airball.png",
        'title': 'Airballs',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000],
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
          imagePath: achievements[index]['imagePath'] as String,
          title: achievements[index]['title'] as String,
          currentProgress: achievements[index]['currentProgress'] as int,
          stages: achievements[index]['stages'] as List<int>,
        );
      },
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required String imagePath,
    required String title,
    required int currentProgress,
    required List<int> stages,
  }) {
    // Ensure the stages list is not empty or invalid
    if (stages.isEmpty) {
      return const SizedBox(); // Avoid rendering a card if stages are empty
    }

    int stageIndex = _getCurrentStageIndex(currentProgress, stages);
    if (stageIndex < 0 || stageIndex >= stages.length) {
      stageIndex = 0; // Default to the first stage if index is invalid
    }

    Color stageColor = (currentProgress == 0 || currentProgress < stages[1])
        ? Colors.grey // Grey color for no achievement
        : _getStageColor(stageIndex);

    double progressPercentage =
        (currentProgress / stages[stageIndex]).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        _showAchievementDialog(
            context, title, currentProgress, stages, imagePath);
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
              Image.asset(
                "assets/$imagePath",
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(stageColor),
              ),
              const SizedBox(height: 2),
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

  void _showAchievementDialog(
    BuildContext context,
    String title,
    int currentProgress,
    List<int> stages,
    String imagePath, // Add imagePath as a parameter
  ) {
    // Determine the current stage index
    int stageIndex = _getCurrentStageIndex(currentProgress, stages);

    // Define stage colors for each stage
    List<Color> stageColors = [
      Colors.grey, // Grey (no achievement earned)
      Colors.brown, // Bronze
      Colors.blue, // Silver
      Colors.amber, // Amber
      Colors.purple // Violet
    ];

    // Ensure valid stage index
    if (stageIndex < 0 || stageIndex >= stageColors.length) {
      stageIndex = 0;
    }

    // Description text
    String description =
        'You have completed $currentProgress out of ${stages.last} for this achievement.\n'
        'Current stage: ${_getStageName(currentProgress, stages)}';

    // Build icons for each stage with the current stage highlighted
    List<Widget> stageIcons = [];
    for (int i = 0; i < stages.length; i++) {
      stageIcons.add(
        Icon(
          Icons.star, // Achievement icon
          size: 40.0,
          color: i == stageIndex
              ? stageColors[i].withOpacity(1.0) // Highlight current stage
              : stageColors[i].withOpacity(0.4), // Dim other stages
        ),
      );
      if (i < stages.length - 1) {
        stageIcons.add(const SizedBox(width: 10.0)); // Spacing between icons
      }
    }

    // Show the custom dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: title,
          description: description,
          imagePath: imagePath, // Dynamically use the passed imagePath
          stageColor: stageColors[stageIndex], // Example stage color
          stageProgress: currentProgress, // Example stage progress
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
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
