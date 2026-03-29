import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/util/level_system.dart';

/// A compact player card for use inside the game screen.
///
/// Two variants:
///  - **UserCard mini** — when [player.user] is non-null. Uses the same
///    slanted-gradient background as the full [UserCard] and shows the
///    player's custom avatar, username, and title.
///  - **Standard card** — when [player.user] is null (guest). Uses a
///    team-color gradient, a generic person icon, and a "Guest" label.
///
/// Both variants show a live [score] badge on the right.
class PlayerCardMini extends StatelessWidget {
  final Player player;
  final Color teamColor;

  const PlayerCardMini({
    super.key,
    required this.player,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return player.user != null ? _buildUserCard() : _buildStandardCard();
  }

  // ── Signed-in user variant ──────────────────────────────────────────────

  Widget _buildUserCard() {
    final user = player.user!;
    final hasAvatar = user.avatarKey.isNotEmpty;
    final hasTitle = user.title.isNotEmpty;
    final titleColor = hasTitle
        ? AchievementsScreen.getColorForUnlockedTitle(user.title, user)
        : Colors.white54;
    final level = LevelSystem.levelFromXp(user.xp);
    final tier = LevelSystem.tierForLevel(level);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Same slanted gradient as the full UserCard
          SvgPicture.asset('assets/slanted-gradient.svg', fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: hasAvatar
                      ? ClipOval(
                          child: SvgPicture.asset(
                            user.mapAvatarKeyToAsset(),
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                          ),
                        )
                      : const Icon(Icons.person,
                          color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasTitle)
                        Text(
                          user.title,
                          style: TextStyle(color: titleColor, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tier.color.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: tier.color, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        'Lv $level',
                        style: TextStyle(
                          color: tier.color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _ScoreBadge(score: player.score.toInt()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Guest / standard variant ────────────────────────────────────────────

  Widget _buildStandardCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            teamColor.withValues(alpha: 0.85),
            teamColor.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Guest',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            _ScoreBadge(score: player.score.toInt()),
          ],
        ),
      ),
    );
  }
}

// ── Score badge ─────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black38,
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
