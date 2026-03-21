import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/util/level_system.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTitleTap;
  final VoidCallback onAvatarTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onTitleTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarAsset = 'assets/avatars/${user.avatarKey}.svg';
    final level = LevelSystem.levelFromXp(user.xp);
    final tier = LevelSystem.tierForLevel(level);

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tier.color, width: 2),
      ),
      elevation: 5.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Background — SVG for default, programmatic gradient for others
            Positioned.fill(
              child: user.backgroundKey.isEmpty ||
                      user.backgroundKey == 'bg_default'
                  ? SvgPicture.asset(
                      'assets/slanted-gradient.svg',
                      fit: BoxFit.cover,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppBackgrounds.gradientFor(user.backgroundKey),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tier.color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: tier.color.withValues(alpha: 0.7),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: tier.color, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Lv $level',
                              style: TextStyle(
                                color: tier.color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tier.displayName,
                              style: TextStyle(
                                color: tier.color.withValues(alpha: 0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Username + avatar row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: onTitleTap,
                            child: Text(
                              user.title.isNotEmpty
                                  ? user.title
                                  : 'No Title Yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: user.title.isNotEmpty
                                    ? AchievementsScreen
                                        .getColorForUnlockedTitle(
                                            user.title, user)
                                    : Colors.white54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: tier.color, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: ClipOval(
                              child: SvgPicture.asset(
                                avatarAsset,
                                fit: BoxFit.cover,
                                width: 56,
                                height: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
