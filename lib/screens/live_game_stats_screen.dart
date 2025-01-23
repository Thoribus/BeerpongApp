import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/models/player.dart';

class LiveGameStatsScreen extends StatefulWidget {
  final String gameId;

  const LiveGameStatsScreen({super.key, required this.gameId});

  @override
  LiveGameStatsScreenState createState() => LiveGameStatsScreenState();
}

class LiveGameStatsScreenState extends State<LiveGameStatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

    /// Recursively computes the difference between two dynamic objects.
  /// If `a` and `b` are equal, returns null. Otherwise, returns a structure
  /// that shows the differences.
  ///
  /// For maps, the returned diff is a map keyed by differing keys with values:
  ///   { 'old': oldValue, 'new': newValue }
  ///
  /// For lists, the diff is a list of changes at each index.
  /// For other types, the diff is simply a map {'old': a, 'new': b}.
  dynamic deepDiff(dynamic a, dynamic b) {
    if (a == b) {
      return null;
    }

    // If both are maps, compare key by key.
    if (a is Map && b is Map) {
      Map<String, dynamic> diffMap = {};
      // Keys present in a or b
      final keys = <String>{...a.keys.cast<String>(), ...b.keys.cast<String>()};
      for (final key in keys) {
        final valueA = a[key];
        final valueB = b[key];
        final diffResult = deepDiff(valueA, valueB);
        if (diffResult != null) {
          diffMap[key] = diffResult;
        }
      }
      return diffMap.isNotEmpty ? diffMap : null;
    }

    // If both are lists, compare element by element.
    if (a is List && b is List) {
      int maxLen = a.length > b.length ? a.length : b.length;
      List<dynamic> diffList = [];
      for (int i = 0; i < maxLen; i++) {
        dynamic itemA = i < a.length ? a[i] : null;
        dynamic itemB = i < b.length ? b[i] : null;
        final diffResult = deepDiff(itemA, itemB);
        diffList.add(diffResult);
      }
      // Remove trailing nulls if they indicate no changes in the tail
      while (diffList.isNotEmpty && diffList.last == null) {
        diffList.removeLast();
      }
      return diffList.isNotEmpty ? diffList : null;
    }

    // For other types: return a map with the old and new value.
    return {'old': a, 'new': b};
  }

  /// Example function comparing two actions (as maps) using deepDiff.
  /// If no differences are found, returns an empty map.
  Map<String, dynamic> compareActions(
      Map<String, dynamic> previous, Map<String, dynamic> current) {
    final diffResult = deepDiff(previous, current);
    return diffResult is Map<String, dynamic> ? diffResult : {};
  }

  /// Example usage:
  void compareLastTwoActions(List<Map<String, dynamic>> actionStack) {
    if (actionStack.length < 2) {
      print("Not enough actions to compare.");
      return;
    }
    print("Comparing last two actions...");
    final previous = actionStack[actionStack.length - 2];
    final current = actionStack.last;
    final differences = compareActions(previous, current);

    if (differences.isEmpty) {
      print("No differences found.");
    } else {
      print("Differences between last two actions:");
      print(differences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: const Color(0xFFF0AE1D),
            title: const Text(
              'Live Game Stats',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          )),
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getGameDocStream(widget.gameId),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Game not found.',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          // Extract game data
          final gameData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          Team team1 = Team.fromJson(gameData['team1']);
          Team team2 = Team.fromJson(gameData['team2']);

          List<Map<String, dynamic>> actionStack = [];
          for (final action in gameData['actionStack']) {
            actionStack.add(Map<String, dynamic>.from(action));
          }
          compareLastTwoActions(actionStack);


          // Display game-end dialog if applicable
          final winnerField = gameData['winner'];
          if (winnerField != null &&
              winnerField is String &&
              winnerField.isNotEmpty) {
            List<Player> winningPlayers = [];
            if (winnerField == "Team Blue") {
              winningPlayers = team1.players;
            } else if (winnerField == "Team Red") {
              winningPlayers = team2.players;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              DialogHelpers.showGameEndDialog(context, winningPlayers);
            });
          }

          return Column(
            children: [
              _buildTopBracket(team1, team2),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCupLayoutsRow(team1, team2),
                      const SizedBox(height: 20),
                      _buildMatchStats(team1, team2),
                      _buildPlayer(team1, team2)
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBracket(Team team1, Team team2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ Color(0xFFF0AE1D), Color.fromARGB(255, 214, 176, 60)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Round 16',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamLogo('assets/avatars/avatar_catbeer.svg', 'Team Blue'),
              Column(
                children: [
                  Text(
                    '${team1.players[0].score} - ${team2.players[0].score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildTeamLogo('assets/avatars/avatar_catbeer.svg', 'Team Red'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String assetPath, String teamName) {
    return Column(
      children: [
        SvgPicture.asset(
          assetPath,
          height: 60,
          width: 60,
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStats(Team team1, Team team2) {
    // Define stats with their corresponding titles and values for each team
    final stats = [
      {
        'title': 'Score',
        'team1': '${team1.players[0].score}',
        'team2': '${team2.players[0].score}'
      },
      {
        'title': 'Throws',
        'team1': '${team1.players[0].throws}',
        'team2': '${team2.players[0].throws}'
      },
      {
        'title': 'Airballs',
        'team1': '${team1.players[0].airballs}',
        'team2': '${team2.players[0].airballs}'
      },
      {
        'title': 'Misses',
        'team1': '${team1.players[0].misses}',
        'team2': '${team2.players[0].misses}'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Match Stats',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: stats.map((stat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team Blue's stat value
                    Text(
                      stat['team1']!,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Stat title
                    Text(
                      stat['title']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    // Team Red's stat value
                    Text(
                      stat['team2']!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer(Team team1, Team team2) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Players',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                team1.players[0].name,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCupLayoutsRow(Team team1, Team team2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 200, // Adjust height for the cup layouts
        decoration: BoxDecoration(
          color: Colors.brown[900], // Background color for the container
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        child: Stack(
          children: [
            // Left Cup Layout
            Positioned(
              left: -90, // tricked the padding but overflows in the middle
              top: 10,
              bottom: 10,
              child: Transform.rotate(
                angle: -90 * 3.14159 / 180, // Rotate counterclockwise
                child: Transform.scale(
                  scale: 0.5, // Scale to fit within the bounds
                  child: CupLayout.buildCupsArea(team: team1),
                ),
              ),
            ),
            // Right Cup Layout
            Positioned(
              right: -90, // tricked the padding but overflows in the middle
              top: 10,
              bottom: 10,
              child: Transform.rotate(
                angle: 90 * 3.14159 / 180, // Rotate clockwise
                child: Transform.scale(
                  scale: 0.5, // Scale to fit within the bounds
                  child: CupLayout.buildCupsArea(team: team2),
                ),
              ),
            ),
            // Divider
            Center(
              child: Container(
                width: 1,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
