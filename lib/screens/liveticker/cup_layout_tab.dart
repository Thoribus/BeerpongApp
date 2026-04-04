import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';

class CupLayoutTab extends StatelessWidget {
  final LiveGameData gameData;
  const CupLayoutTab({required this.gameData, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Blue Team bracket
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTeamBracket(context, gameData.team1, isLeftSide: true),
          ),

          const SizedBox(height: 16),

          // Cup layout in center
          _buildCupLayoutsRow(context, gameData.team1, gameData.team2),

          const SizedBox(height: 16),

          // Red Team bracket (mirrored)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                _buildTeamBracket(context, gameData.team2, isLeftSide: false),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTeamBracket(BuildContext context, Team team,
      {required bool isLeftSide}) {
    final bool isLeft = isLeftSide;
    final badgeTitles = [context.loc.liveStatCupsHit, context.loc.liveStatAirballs, context.loc.liveStatThrows, context.loc.liveStatMisses];
    final c = AppColors.of(context);

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: isLeft
                ? BorderSide(color: team.color, width: 4)
                : BorderSide.none,
            right: isLeft
                ? BorderSide.none
                : BorderSide(color: team.color, width: 4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Avatars + Names stacked vertically
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment:
                    isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: team.players.map((player) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildAvatarName(context, player, alignLeft: isLeft),
                  );
                }).toList(),
              ),
            ),

            // Right Column: Stat badges stacked vertically aligned with each player
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // First row: badge titles above the numbers
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: badgeTitles.map((title) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 8,
                              color: c.subtle,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Then badges rows for each player (only numbers, no labels)
                  ...team.players.map((player) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildStatBadgesRowOnlyNumbers(context, player),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
    );
  }

// Build badges row with only numbers, no labels
  Widget _buildStatBadgesRowOnlyNumbers(BuildContext context, Player player) {
    final c = AppColors.of(context);
    final stats = [
      player.cupsHit.length.toString(),
      player.airballs.toString(),
      player.throws.toString(),
      player.misses.toString(),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stats.map((value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.onBackground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatarName(BuildContext context, Player player, {required bool alignLeft}) {
    final c = AppColors.of(context);
    final avatar = player.user == null
        ? CircleAvatar(
            radius: 16,
            backgroundColor: c.border,
            child: Icon(Icons.person, color: c.subtle, size: 18),
          )
        : CircleAvatar(
            radius: 16,
            backgroundColor: c.border,
            child: ClipOval(
              child: SvgPicture.asset(
                player.user!.mapAvatarKeyToAsset(),
                fit: BoxFit.cover,
                width: 32,
                height: 32,
              ),
            ),
          );

    final nameText = Flexible(
      child: Text(
        player.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: c.onBackground,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignLeft
          ? [
              avatar,
              const SizedBox(width: 8),
              nameText,
            ]
          : [
              nameText,
              const SizedBox(width: 8),
              avatar,
            ],
    );
  }

  Widget _buildCupLayoutsRow(BuildContext context, Team team1, Team team2) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              // Left Cup Layout
              Positioned(
                right: 160,
                top: 10,
                bottom: 10,
                child: OverflowBox(
                  maxHeight: double.infinity,
                  child: Transform.rotate(
                    angle: -90 * 3.14159 / 180,
                    child: Transform.scale(
                      scale: 0.5,
                      child: CupLayout.buildCupsArea(team: team1),
                    ),
                  ),
                ),
              ),
              // Right Cup Layout
              Positioned(
                left: 160,
                top: 10,
                bottom: 10,
                child: OverflowBox(
                  maxHeight: double.infinity,
                  child: Transform.rotate(
                    angle: 90 * 3.14159 / 180,
                    child: Transform.scale(
                      scale: 0.5,
                      child: CupLayout.buildCupsArea(team: team2),
                    ),
                  ),
                ),
              ),
              // Divider
              Center(
                child: Container(
                  width: 1,
                  color: c.divider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
