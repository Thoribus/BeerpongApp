import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/widgets/user_card.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomUserScreen extends StatefulWidget {
  final User user;

  const CustomUserScreen({super.key, required this.user});

  @override
  State<CustomUserScreen> createState() => _CustomUserScreenState();
}

class _CustomUserScreenState extends State<CustomUserScreen> {
  String? selectedIcon;
  String? selectedAchievement;
  String? selectedTitle;

  final List<String> availableIcons = [
    'assets/avatars/avatar_aggroracoon.png',
    'assets/avatars/avatar_catbeer.png',
    'assets/avatars/avatar_catpants.png',
    'assets/avatars/avatar_cheering.png',
    'assets/avatars/avatar_cupbeer.png',
    'assets/avatars/avatar_frogisland.png',
  ];

  final List<String> availableAchievements = [
    'assets/achievements/ach_holyknight.png',
    'assets/achievements/ach_animalparty.png',
    'assets/achievements/ach_catblock.png',
    'assets/achievements/ach_catsniper.png',
    'assets/achievements/ach_moletable.png',
    'assets/achievements/ach_racoontrophy.png',
    'assets/achievements/ach_cheersshot.png',
    'assets/achievements/ach_sadlooser.png',
    'assets/achievements/ach_twerkfrog.png',
    'assets/achievements/ach_header.png',
  ];

  final List<String> availableTitles = [
    'Beginner',
    'Pro Player',
    'Champion',
  ];

  void _resetSelections() {
    setState(() {
      selectedIcon = null;
      selectedAchievement = null;
      selectedTitle = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selections saved and reset.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetSelections,
        label: const Text("Save"),
        icon: const Icon(Icons.save),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<UserStatsInGame>>(
        future: FirestoreService().retrieveUserStatsWithDate(widget.user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: UserCard(
                    user: widget.user,
                    onTitleTap: () {},
                    onAvatarTap: () {},
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Choose User Icon'),
                _buildIconGrid(availableIcons, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),

                _buildSectionTitle('Choose Achievement Icon'),
                _buildIconGridOptimized(
                  icons: availableAchievements,
                  selected: selectedAchievement,
                  onSelect: (icon) {
                    setState(() => selectedAchievement = icon);
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Choose Title'),
                _buildTitleSelection(),
                const SizedBox(height: 80), // Leave room for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIconGrid(
    List<String> icons,
    String? selected,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.map((iconPath) {
        final isSelected = selected == iconPath;
        return GestureDetector(
          onTap: () => onSelect(iconPath),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 3,
              ),
            ),
            child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                child: Image.asset(iconPath,
                    width: 36, height: 36, fit: BoxFit.cover)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleSelection() {
    return Wrap(
      spacing: 8,
      children: availableTitles.map((title) {
        final isSelected = selectedTitle == title;
        return ChoiceChip(
          label: Text(title),
          selected: isSelected,
          onSelected: (_) => setState(() => selectedTitle = title),
          selectedColor: Colors.orange.shade100,
          labelStyle: TextStyle(
            color: isSelected ? Colors.orange : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconGridOptimized({
    required List<String> icons,
    required String? selected,
    required Function(String) onSelect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int crossAxisCount = 4;
        const double spacing = 12;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return GridView.builder(
          itemCount: icons.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final iconPath = icons[index];
            final isSelected = selected == iconPath;

            return GestureDetector(
              onTap: () => onSelect(iconPath),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Image.asset(iconPath,
                      width: 36, height: 36, fit: BoxFit.cover),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
