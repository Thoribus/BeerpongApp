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
    'assets/icons/avatar1.svg',
    'assets/icons/avatar2.svg',
    'assets/icons/avatar3.svg',
  ];

  final List<String> availableAchievements = [
    'assets/achievements/trophy1.svg',
    'assets/achievements/trophy2.svg',
    'assets/achievements/trophy3.svg',
  ];

  final List<String> availableTitles = [
    'Beginner',
    'Pro Player',
    'Champion',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<UserStatsInGame>>(
              future: FirestoreService().retrieveUserStatsWithDate(widget.user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                return Column(
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
                    _buildIconSelection(
                      availableIcons,
                      selectedIcon,
                      onSelect: (icon) {
                        setState(() {
                          selectedIcon = icon;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Choose Achievement Icon'),
                    _buildIconSelection(
                      availableAchievements,
                      selectedAchievement,
                      onSelect: (icon) {
                        setState(() {
                          selectedAchievement = icon;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Choose Title'),
                    _buildTitleSelection(),
                  ],
                );
              },
            ),
          ],
        ),
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

  Widget _buildIconSelection(List<String> icons, String? selected,
      {required Function(String) onSelect}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: icons.map((iconPath) {
          final isSelected = selected == iconPath;
          return GestureDetector(
            onTap: () => onSelect(iconPath),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                child: SvgPicture.asset(iconPath, width: 36, height: 36),
              ),
            ),
          );
        }).toList(),
      ),
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
          onSelected: (_) {
            setState(() {
              selectedTitle = title;
            });
          },
          selectedColor: Colors.orange.shade100,
          labelStyle: TextStyle(
            color: isSelected ? Colors.orange : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }
}
