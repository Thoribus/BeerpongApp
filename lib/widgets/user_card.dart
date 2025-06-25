// lib/widgets/user_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/achievements_screen.dart';

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

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/slanted-gradient.svg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.star, size: 20, color: Colors.white),
                      ),
                    );
                  })),
                  const SizedBox(height: 10),
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
                                      : Colors.white,
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
                          ]),
                      GestureDetector(
                        onTap: onAvatarTap,
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
