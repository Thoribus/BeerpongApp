import 'package:beerpongapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';

class PersonalStatisticsScreen extends StatelessWidget {
  final User user;

  const PersonalStatisticsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildStatisticsTiles(user),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTiles(User user) {
    final stats = [
      {'icon': Icons.score, 'title': 'Total Score', 'value': user.totalScore},
      {
        'icon': Icons.air,
        'title': 'Total Airballs',
        'value': user.totalAirballs
      },
      {
        'icon': Icons.sports_bar,
        'title': 'Cups Hit',
        'value': user.cupsHit.length
      },
      {'icon': Icons.emoji_events, 'title': 'Wins', 'value': user.wins},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5, // Half the height
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final c = AppColors.of(context);
        return Container(
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.chip,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stat['value']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.onBackground,
                      ),
                    ),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: c.subtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
