import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';

class GameHighlightsScreen extends StatelessWidget {
  final User oldUser;
  // userId -> { "totalScore": x, "wins": y, ... }

  const GameHighlightsScreen({
    Key? key,
    required this.oldUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build a list of "improvements"
    final improvements = <_UserImprovement>[];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final User updatedUser = userProvider.user!;

    final scoreChange = updatedUser.totalScore - oldUser.totalScore;
    final winsChange = updatedUser.wins - oldUser.wins;
    final lossesChange = updatedUser.losses - oldUser.losses;

    improvements.add(
      _UserImprovement(
        user: updatedUser,
        oldScore: oldUser.totalScore,
        newScore: updatedUser.totalScore,
        scoreChange: scoreChange,
        winsChange: winsChange,
        lossesChange: lossesChange,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Highlights'),
      ),
      body: ListView.builder(
        itemCount: improvements.length,
        itemBuilder: (context, index) {
          final imp = improvements[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(imp.user.username),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score: ${imp.oldScore} -> ${imp.newScore} '
                      '(Change: ${imp.scoreChange.toStringAsFixed(1)})'),
                  Text('Wins change: +${imp.winsChange}'),
                  Text('Losses change: +${imp.lossesChange}'),
                  // Possibly a new hitrate if you track that
                  // ...
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserImprovement {
  final User user;
  final double oldScore;
  final double newScore;
  final double scoreChange;
  final int winsChange;
  final int lossesChange;

  _UserImprovement({
    required this.user,
    required this.oldScore,
    required this.newScore,
    required this.scoreChange,
    required this.winsChange,
    required this.lossesChange,
  });
}
