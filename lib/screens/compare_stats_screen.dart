import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/user.dart';

class ComparisonScreen extends StatelessWidget {
  final User currentUser;
  final User friend;

  const ComparisonScreen({
    super.key,
    required this.currentUser,
    required this.friend,
  });

  /// Maps avatarKey -> local asset path (e.g. 'cat' -> 'assets/avatars/cat.png').
  String _mapAvatarKeyToAsset(String avatarKey) {
    if (avatarKey.isEmpty) return '';
    return 'assets/avatars/$avatarKey.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Stats'),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        color: Colors.black, // Full-screen background color
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildComparisonTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(currentUser),
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        _buildPlayerCard(friend),
      ],
    );
  }

  Widget _buildPlayerCard(User user) {
    return SizedBox(
      width: 150, // Fixed width for player cards
      height: 280, // Fixed height for player cards
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: SvgPicture.asset(
                    _mapAvatarKeyToAsset(user.avatarKey),
                    fit: BoxFit.cover,
                    width: 40 * 2,
                    height: 40 * 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2, // Allow up to 2 lines for the name
                overflow:
                    TextOverflow.ellipsis, // Truncate with ellipsis if too long
                textAlign: TextAlign.center,
              ),
              Text(
                user.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatRow(
                'Total Score', currentUser.totalScore, friend.totalScore),
            _buildDivider(),
            _buildStatRow(
                'Total Misses', currentUser.totalMisses, friend.totalMisses,
                lowerIsBetter: true),
            _buildDivider(),
            _buildStatRow('Total Airballs', currentUser.totalAirballs,
                friend.totalAirballs,
                lowerIsBetter: true),
            _buildDivider(),
            _buildStatRow(
                'Total Throws', currentUser.totalThrows, friend.totalThrows),
            _buildDivider(),
            _buildStatRow('Wins', currentUser.wins, friend.wins),
            _buildDivider(),
            _buildStatRow('Losses', currentUser.losses, friend.losses,
                lowerIsBetter: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String stat, dynamic currentUserValue, dynamic friendValue,
      {bool lowerIsBetter = false}) {
    final bool isCurrentUserWinner = lowerIsBetter
        ? currentUserValue < friendValue
        : currentUserValue > friendValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current User Value
          Text(
            currentUserValue.toString(),
            style: TextStyle(
              color: isCurrentUserWinner ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Stat Name
          Text(
            stat,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          // Friend Value
          Text(
            friendValue.toString(),
            style: TextStyle(
              color: isCurrentUserWinner ? Colors.red : Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[800],
      thickness: 1,
    );
  }
}
