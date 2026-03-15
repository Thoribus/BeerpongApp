import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
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
    super.key,
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
          image: const DecorationImage(
            image: AssetImage('assets/background_achievement.png'),
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
              image: AssetImage('assets/$imagePath'),
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
                '$stageProgress', // Display progress
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

  static void checkAchievements(User user) async {
    bool changed = false;
    List<Map<String, Object>> achievements = getAchievements(user);

    for (var ach in achievements) {
      List<int> stages = ach['stages'] as List<int>;
      int stage1Threshold = stages[1];
      int currentProgress = ach['currentProgress'] as int;
      String titleToGrant = ach['titleToGrant'] as String;

      // If user has not unlocked this title yet, check if they meet stage1 threshold
      if (currentProgress >= stage1Threshold &&
          !user.unlockedTitles.contains(titleToGrant)) {
        user.unlockedTitles.add(titleToGrant);
        changed = true;
      }
    }

    if (changed) {
      await FirestoreService.instance.updateUser(user);
    }
  }

  static List<Map<String, String>> getUpgradedAchivements(Player player) {
    if (player.user == null) {
      return [];
    }
    List<Map<String, String>> upgradedAchievements = [];
    List<Map<String, Object>> achievements = getAchievements(player.user!);
    List<Map<String, Object>> updatedAchivements =
        getAchievements(FirestoreService.mapPlayerToUser(player));

    for (var ach in achievements) {
      List<int> stages = ach['stages'] as List<int>;
      int currentStage =
          _getCurrentStageIndex(ach['currentProgress'] as int, stages);
      final achievement = updatedAchivements
          .firstWhere((element) => element['title'] == ach['title']);
      int newStage =
          _getCurrentStageIndex(achievement['currentProgress'] as int, stages);
      if (newStage > currentStage) {
        upgradedAchievements.add({
          'title': ach['title'] as String,
          'oldStage': currentStage.toString(),
          'newStage': newStage.toString(),
        });
      }
    }

    return upgradedAchievements;
  }

  static List<Map<String, Object>> getAchievements(User user) {
    List<Map<String, Object>> achievements = [
      {
        'imagePath': 'ach_wins.png',
        'title': 'Wins',
        'titleToGrant': 'Beginner Winner',
        'currentProgress': user.wins,
        'stages': [0, 25, 50, 100, 100], // Bronze, Silver, Amber, Violet
      },
      {
        'imagePath': 'ach_lost.png',
        'title': 'Losses',
        'titleToGrant': 'Unlucky Warrior',
        'currentProgress': user.losses,
        'stages': [0, 25, 50, 100, 100],
      },
      {
        'imagePath': 'ach_friends.png',
        'title': 'Friendships',
        'titleToGrant': 'Social Butterfly',
        'currentProgress': user.friends.length,
        'stages': [0, 5, 15, 20, 100],
      },
      {
        'imagePath': 'ach_champion.png',
        'title': 'Champion',
        'titleToGrant': 'Heavy hitter',
        'currentProgress': user.totalScore.round(),
        'stages': [0, 20, 100, 1000, 5000],
      },
      {
        'imagePath': 'ach_loses.png',
        'title': 'Misses',
        'titleToGrant': 'Clumsy',
        'currentProgress': user.totalMisses,
        'stages': [0, 25, 50, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': 0, //user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': 1001, //user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
      {
        'imagePath': 'ach_airball.png',
        'title': 'Airballs',
        'titleToGrant': 'Airballer',
        'currentProgress': user.totalAirballs,
        'stages': [0, 10, 20, 1000, 5000],
      },
    ];
    return achievements;
  }

  /// Given a 'titleToGrant' like "Heavy hitter", find the corresponding
  /// achievements row. E.g., row with 'titleToGrant' == "Heavy hitter".
  static Map<String, Object>? findAchievementForTitle(
      String titleToGrant, User user) {
    // Build the achievements list for this user
    final achievements = AchievementsScreen.getAchievements(user);

    // Find the row that has 'titleToGrant' == the passed-in string
    for (var ach in achievements) {
      if (ach['titleToGrant'] == titleToGrant) {
        return ach;
      }
    }
    return null; // Not found
  }

  /// Then you can compute the color for that title
  static Color getColorForUnlockedTitle(String titleToGrant, User user) {
    final ach = findAchievementForTitle(titleToGrant, user);
    if (ach == null) {
      return Colors.grey; // If for some reason we can't find it
    }

    // stage logic:
    final currentProgress = ach['currentProgress'] as int;
    final stages = ach['stages'] as List<int>;
    final stageIndex = _getCurrentStageIndex(currentProgress, stages);
    return _getStageColor(stageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
    // Dummy data
    const String username = 'PlayerOne';
    const int level = 12;
    const int achievementsCompleted = 32;
    const int totalAchievements = 50;
    final double progress =
        (achievementsCompleted / totalAchievements).clamp(0.0, 1.0);

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with avatar and name
            Row(
              children: [
                // Level Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Lv $level',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Username & Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '$achievementsCompleted / $totalAchievements Achievements',
                        style: TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Achievement emblems row
            Row(
              children: [
                const Text(
                  'Emblems:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.star, color: Colors.amber[800]),
                const SizedBox(width: 6),
                Icon(Icons.military_tech, color: Colors.grey[700]),
                const SizedBox(width: 6),
                const Icon(Icons.emoji_events, color: Colors.deepOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    List<Map<String, Object>> achievements = getAchievements(user);
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
        color: stageColor,
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
                'assets/$imagePath',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white) // stage color einfügen wenn progress stimmt
                  //valueColor: AlwaysStoppedAnimation<Color>(stageColor),
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

  static int _getCurrentStageIndex(int currentProgress, List<int> stages) {
    // Return the current stage index based on progress
    for (int i = stages.length - 1; i >= 0; i--) {
      if (currentProgress >= stages[i]) {
        return i;
      }
    }
    return 0; // Default to first stage
  }

  static Color _getStageColor(int stageIndex) {
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
              ? stageColors[i].withValues(alpha: 1.0) // Highlight current stage
              : stageColors[i].withValues(alpha: 0.4), // Dim other stages
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
