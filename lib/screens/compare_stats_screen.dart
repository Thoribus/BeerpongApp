import 'package:flutter/material.dart';
import '../models/user.dart';

class ComparisonScreen extends StatelessWidget {
  final User currentUser;
  final User friend;

  const ComparisonScreen({
    Key? key,
    required this.currentUser,
    required this.friend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Stats'),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${currentUser.username} vs ${friend.username}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        _buildTableRow('Stat', currentUser.username, friend.username, isHeader: true),
        _buildTableRow('Total Score', currentUser.totalScore, friend.totalScore),
        _buildTableRow('Total Misses', currentUser.totalMisses, friend.totalMisses, lowerIsBetter: true),
        _buildTableRow('Total Airballs', currentUser.totalAirballs, friend.totalAirballs, lowerIsBetter: true),
        _buildTableRow('Total Throws', currentUser.totalThrows, friend.totalThrows),
        _buildTableRow('Wins', currentUser.wins, friend.wins),
        _buildTableRow('Losses', currentUser.losses, friend.losses, lowerIsBetter: true),
        _buildTableRow('Win Rate', currentUser.winRate, friend.winRate, isPercentage: true),
      ],
    );
  }

  TableRow _buildTableRow(String stat, dynamic currentUserValue, dynamic friendValue, {bool isHeader = false, bool lowerIsBetter = false, bool isPercentage = false}) {
    Color currentUserColor = Colors.white;
    Color friendColor = Colors.white;

    if (!isHeader) {
      if (currentUserValue == friendValue) {
        currentUserColor = Colors.white;
        friendColor = Colors.white;
      } else if (lowerIsBetter) {
        currentUserColor = currentUserValue < friendValue ? Colors.green : Colors.red;
        friendColor = friendValue < currentUserValue ? Colors.green : Colors.red;
      } else {
        currentUserColor = currentUserValue > friendValue ? Colors.green : Colors.red;
        friendColor = friendValue > currentUserValue ? Colors.green : Colors.red;
      }
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            stat,
            style: TextStyle(
              color: isHeader ? Colors.amber : Colors.white,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 16 : 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isPercentage ? '${(currentUserValue * 100).toStringAsFixed(2)}%' : currentUserValue.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isHeader ? Colors.amber : currentUserColor,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 16 : 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isPercentage ? '${(friendValue * 100).toStringAsFixed(2)}%' : friendValue.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isHeader ? Colors.amber : friendColor,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
