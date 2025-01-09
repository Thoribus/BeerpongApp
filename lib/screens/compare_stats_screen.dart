import 'package:flutter/material.dart';
import '../models/user.dart';

class ComparisonScreen extends StatelessWidget {
  final User currentUser;
  final User friend;

  const ComparisonScreen({
    super.key,
    required this.currentUser,
    required this.friend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Stats'),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        color: Colors.black, // Set the background color to black
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildUserInfo(currentUser),
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        _buildUserInfo(friend),
      ],
    );
  }

  Widget _buildUserInfo(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(
              'assets/avatars/cat.png'), // Replace with your image asset
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Column(
      children: [
        _buildStatRow('Total Score', currentUser.totalScore, friend.totalScore),
        _buildStatRow(
            'Total Misses', currentUser.totalMisses, friend.totalMisses,
            lowerIsBetter: true),
        _buildStatRow(
            'Total Airballs', currentUser.totalAirballs, friend.totalAirballs,
            lowerIsBetter: true),
        _buildStatRow(
            'Total Throws', currentUser.totalThrows, friend.totalThrows),
        _buildStatRow('Wins', currentUser.wins, friend.wins),
        _buildStatRow('Losses', currentUser.losses, friend.losses,
            lowerIsBetter: true),
        _buildStatRow('Win Rate', currentUser.winRate, friend.winRate,
            isPercentage: true),
      ],
    );
  }

  Widget _buildStatRow(
      String stat, dynamic currentUserValue, dynamic friendValue,
      {bool lowerIsBetter = false, bool isPercentage = false}) {
    final bool isCurrentUserWinner = lowerIsBetter
        ? currentUserValue < friendValue
        : currentUserValue > friendValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Current User Value
          Expanded(
            child: Text(
              isPercentage
                  ? '${(currentUserValue * 100).toStringAsFixed(2)}%'
                  : currentUserValue.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrentUserWinner ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Stat Name
          Expanded(
            child: Text(
              stat,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          // Friend Value
          Expanded(
            child: Text(
              isPercentage
                  ? '${(friendValue * 100).toStringAsFixed(2)}%'
                  : friendValue.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrentUserWinner ? Colors.red : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
