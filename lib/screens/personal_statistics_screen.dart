import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/widgets/user_card.dart';

class PersonalStatisticsScreen extends StatelessWidget {
  final User user;

  const PersonalStatisticsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Load userStatsInGame from Firestore
            FutureBuilder<List<UserStatsInGame>>(
              future: FirestoreService().retrieveUserStatsWithDate(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final userStatsList = snapshot.data ?? [];

                // 2) Now we have userStatsList for line charts etc.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: UserCard(
                          user: user,
                          onTitleTap: () {},
                          onAvatarTap: () {},
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Example "Statistics Tiles" if you want them:
                    _buildStatisticsTiles(user),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                  color: Colors.grey,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      stat['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
