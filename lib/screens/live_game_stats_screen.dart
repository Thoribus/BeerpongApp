import 'package:beerpongapp/beerpong_icons_icons.dart';
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

class LiveGameStatsScreenState extends State<LiveGameStatsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Text(
            'Select $title',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold, // Make the title text bold
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Back'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Table'),
                  Tab(text: 'Statistics'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Settings'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCupLayoutTab(team1, team2),
                    _buildStatisticsTab(team1, team2),
                    _buildTimelineTab(gameData['actionStack'] ?? []),
                    _buildSettingsTab(gameData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCupLayoutTab(Team team1, Team team2) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Left Team Players above the cup layout

          const SizedBox(height: 16),

          _buildPlayerTable(team1, isLeft: true),

          const SizedBox(height: 16),

          _buildCupLayoutsRow(team1, team2),

          const SizedBox(height: 16),

          // Right Team Players beneath the cup layout
          _buildPlayerTable(team2, isLeft: false, mirrored: true),
        ],
      ),
    );
  }

  Widget _buildPlayerTable(Team team,
      {required bool isLeft, bool mirrored = false}) {
    return Table(
      columnWidths: {
        0: FlexColumnWidth(mirrored ? 2 : 3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(mirrored ? 3 : 2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Table Header
        TableRow(
          children: [
            const SizedBox(), // Empty header for player name column
            const Icon(Icons.sports_bar, color: Colors.amber, size: 16), // Cups
            const Icon(BeerpongIcons.airball, color: Colors.amber, size: 20),
            // Airball
            const Icon(Icons.sports_handball,
                color: Colors.amber, size: 16), // Throws
            const Icon(Icons.close, color: Colors.amber, size: 16), // Misses
          ],
        ),

        // Player Rows
        ...team.players.map(
          (player) => TableRow(
            children: mirrored
                ? [
                    Text((player.cupsHit).length.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                    Text(player.airballs.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                    Text(player.throws.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                    Text(player.misses.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildPlayerName(player),
                    ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildPlayerName(player),
                    ),
                    Text(
                      (player.cupsHit).length.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      player.airballs.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(player.throws.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                    Text(player.misses.toString(),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white)),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(Team team1, Team team2) {
    return _buildMatchStats(team1, team2);
  }

  Widget _buildTimelineTab(List<dynamic> actionStack) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: actionStack.length,
      itemBuilder: (context, index) {
        final action = actionStack[index];

        return Card(
          color: Colors.black.withOpacity(0.8),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12.0),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20.0,
                  backgroundImage: NetworkImage(action['playerIcon'] ??
                      'assets/avatars/avatar_catbeer.svg'),
                ),
                const SizedBox(width: 10.0),
                Text(
                  action['playerName'] ?? 'Unknown Player',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  action['timestamp'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                action['description'] ?? 'Unknown action',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }

  void main() {
    runApp(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Beer Pong Game Timeline"),
        ),
        body: _buildTimelineTab([
          {
            'playerName': 'John Doe',
            'playerIcon': 'assets/avatars/avatar_catbeer.svg',
            'description': 'John made a successful shot!',
            'timestamp': '12:05 PM',
          },
          {
            'playerName': 'Jane Smith',
            'playerIcon': 'assets/avatars/avatar_catbeer.svg',
            'description': 'Jane missed the shot!',
            'timestamp': '12:07 PM',
          },
          {
            'playerName': 'John Doe',
            'playerIcon': 'assets/avatars/avatar_catbeer.svg',
            'description': 'John scores again!',
            'timestamp': '12:09 PM',
          },
        ]),
      ),
    ));
  }

  Widget _buildSettingsTab(Map<String, dynamic> gameData) {
    return SingleChildScrollView(
      // To make the content scrollable if needed
      child: Center(
        child: Column(
          children: [
            // Add the Bracket Section
            _buildBracketSection(
              title: 'Deathcup',
              imagePath:
                  'assets/racoon_winner.svg', // Replace with your image path
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'When a cup is hit and not cleared from the field or a cup that someone holding is hit, it is declared as a deathcup.\n',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'The team that hits the deathcup automatically wins!',
                    style: TextStyle(color: Colors.white),
                  ),
                  // Add more rules as needed
                ],
              ),
              infoMessage: 'This section explains the game rules in detail.',
            ),
            _buildBracketSection(
              title: 'Island',
              imagePath:
                  'assets/frog_island.svg', // Replace with your image path
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'A player can declare an island-shot (once per game) when a single cup has no surrounding cups.\n',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'When an ISLAND is hit, an additional cup is cleared from the field!',
                    style: TextStyle(color: Colors.white),
                  ),
                  // Add more player info as needed
                ],
              ),
              infoMessage: 'This section provides player details and stats.',
            ),
            _buildBracketSection(
              title: 'Putback',
              imagePath:
                  'assets/cat_boxing.svg', // Replace with your image path
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'When the last cup is hit, the enemy team has a chance to revoke the cuphit.\n',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Each player of the losing team has the chance to score a putback!',
                    style: TextStyle(color: Colors.white),
                  ),
                  // Add more player info as needed
                ],
              ),
              infoMessage: 'This section provides player details and stats.',
            ),
            // You can add more sections as needed
          ],
        ),
      ),
    );
  }

  Widget _buildTopBracket(Team team1, Team team2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0AE1D), Color.fromARGB(255, 214, 176, 60)],
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
                    '${totalScore(team1)} - ${totalScore(team2)}',
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

  num totalScore(Team team) {
    return team.players.map((player) => player.score).reduce((a, b) => a + b);
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
    final stats = [
      {
        'title': 'Score',
        'team1': team1.players[0].score.toDouble(),
        'team2': team2.players[0].score.toDouble()
      },
      {
        'title': 'Throws',
        'team1': team1.players[0].throws.toDouble(),
        'team2': team2.players[0].throws.toDouble()
      },
      {
        'title': 'Airballs',
        'team1': team1.players[0].airballs.toDouble(),
        'team2': team2.players[0].airballs.toDouble()
      },
      {
        'title': 'Misses',
        'team1': team1.players[0].misses.toDouble(),
        'team2': team2.players[0].misses.toDouble()
      },
      // New placeholder stats
      {
        'title': 'Accuracy',
        'team1': 65.0,
        'team2': 58.0,
      },
      {
        'title': 'Rebounds',
        'team1': 12.0,
        'team2': 15.0,
      },
      {
        'title': 'Blocks',
        'team1': 3.0,
        'team2': 5.0,
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
              fontSize: 18, // Reduced font size
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          Column(
            children: stats.map((stat) {
              double team1Value = stat['team1'] as double;
              double team2Value = stat['team2'] as double;
              double maxStatValue =
                  team1Value > team2Value ? team1Value : team2Value;

              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 6.0), // Compact vertical padding
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          team1Value.toString(),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14, // Smaller font
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stat['title'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14, // Smaller font
                          ),
                        ),
                        Text(
                          team2Value.toString(),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14, // Smaller font
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: (((team1Value + 1) / (maxStatValue + 1)) * 100)
                              .round(),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(
                                  4), // Rounded edge on the left
                            ),
                            child: Container(
                              height: 6, // Thinner bar
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (((team2Value + 1) / (maxStatValue + 1)) * 100)
                              .round(),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(
                                  4), // Rounded edge on the right
                            ),
                            child: Container(
                              height: 6, // Thinner bar
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
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
        height: 200,
        decoration: BoxDecoration(
          color: Color.fromARGB(
              255, 214, 176, 60), // Background color for the container
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        child: Stack(
          children: [
            // Left Cup Layout
            Positioned(
              right: 180, // tricked the padding but overflows in the middle
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
              left: 180, // tricked the padding but overflows in the middle
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

Widget _buildBracketSection({
  required String title,
  required String imagePath,
  required Widget content,
  required String infoMessage,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              //_showInfoDialog(title, infoMessage);
            },
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              child: const Icon(
                Icons.info,
                color: Colors.amber,
                size: 14,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Expanded(child: content),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

Widget _buildPlayerName(Player player) {
  return Container(
    padding: const EdgeInsets.all(8.0), // Inner padding
    decoration: BoxDecoration(
      color: Colors.brown.shade600, // Background color for card
      border: Border.all(
        color: Colors.grey.withOpacity(0.5), // Semi-transparent border
        width: 0.5,
      ),
      borderRadius: BorderRadius.circular(8.0), // Rounded corners
    ),
    child: Row(
      children: [
        player.user == null
            ? const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 8,
                ),
              )
            : CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: SvgPicture.asset(
                    _mapAvatarKeyToAsset(player.user!.avatarKey),
                    fit: BoxFit.cover,
                    width: 10 * 2,
                    height: 10 * 2,
                  ),
                ),
              ),
        const SizedBox(width: 8.0), // Space between avatar and text
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name.length > 13
                    ? '${player.name.substring(0, 12)}...' // Truncate long names
                    : player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
                overflow: TextOverflow.ellipsis, // Handles very long names
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Title: X', // Dummy level
                style: TextStyle(color: Colors.grey, fontSize: 8.0),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _mapAvatarKeyToAsset(String avatarKey) {
  if (avatarKey.isEmpty) return '';
  return 'assets/avatars/$avatarKey.svg';
}
