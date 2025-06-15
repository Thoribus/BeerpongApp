import 'package:beerpongapp/models/event.dart';
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
  late DateTime gameStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: const Color(0xFFF0AE1D),
            title: const Column(
              children: [
                Text(
                  'Live Ticker',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Current Game',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                ),
              ],
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

          gameStart = gameData['timestamp'].toDate();

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
                    _buildTimelineTab(team1, team2),
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
          const SizedBox(height: 16),

          // Team Stat Brackets Above Cup Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamStatBracket(team1, isLeft: true),
              _buildTeamStatBracket(team2, isLeft: false),
            ],
          ),

          const SizedBox(height: 16),

          _buildCupLayoutsRow(team1, team2),

          const SizedBox(height: 16),

          // Player Tables Beneath Cup Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayerTable(team1, isLeft: true),
              _buildPlayerTable(team2, isLeft: false, mirrored: true),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the team stat bracket with a gradient background
  Widget _buildTeamStatBracket(Team team, {required bool isLeft}) {
    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 16), // Margin to the sides
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLeft
                ? [Colors.blue.shade700, Colors.grey]
                : [Colors.grey, Colors.red.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: team.players.map((player) {
            return Expanded(
              child: Column(
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
                              player.user!.mapAvatarKeyToAsset(),
                              fit: BoxFit.cover,
                              width: 10 * 2,
                              height: 10 * 2,
                            ),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    player.name.length > 10
                        ? "${player.name.substring(0, 9)}…" // Truncate long names
                        : player.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPlayerTable(Team team,
      {required bool isLeft, bool mirrored = false}) {
    return Column(
      children: [
        // Player Cards
        ...team.players.map((player) {
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16), // Margin to the sides
            elevation: 4.0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isLeft ? Colors.blue.shade700 : Colors.red.shade700,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                              player.user!.mapAvatarKeyToAsset(),
                              fit: BoxFit.cover,
                              width: 10 * 2,
                              height: 10 * 2,
                            ),
                          ),
                        ),
                  // Stats
                  _buildStatBadge(player.cupsHit.length.toString(), "Cups Hit"),
                  _buildStatBadge(player.airballs.toString(), "Airballs"),
                  _buildStatBadge(player.throws.toString(), "Throws"),
                  _buildStatBadge(player.misses.toString(), "Misses"),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// A widget to show stats in a badge style
  Widget _buildStatBadge(String statValue, String statName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statValue,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statName,
          style: const TextStyle(fontSize: 8, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(Team team1, Team team2) {
    return _buildMatchStats(team1, team2);
  }

  Widget _buildTimelineTab(Team team1, Team team2) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("games")
            .doc(widget.gameId)
            .collection("events")
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<GameEvent> events = snapshot.data!.docs
              .map((doc) => GameEvent.fromJson(doc.data(), doc.id, widget.gameId))
              .toList();

          return _buildEventList(events, team1, team2);
        });
  }

  Widget _buildEventList(List<GameEvent> events, Team team1, Team team2) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isTeam1 = event.team != "4294198070";

        return _buildEventRow(event, isTeam1);
      },
    );
  }

  Widget _buildEventRow(GameEvent event, bool isTeam1) {
    Color eventColor = _getEventColor(event.eventType);
    IconData eventIcon = _getEventIcon(event.eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child:
                  isTeam1 ? _buildPlayerInfo(event, eventColor) : const SizedBox()),
          Expanded(child: isTeam1 ? _buildTimestamp(event) : const SizedBox()),
          Icon(eventIcon, color: eventColor),
          Expanded(child: !isTeam1 ? _buildTimestamp(event) : const SizedBox()),
          Expanded(
              child:
                  !isTeam1 ? _buildPlayerInfo(event, eventColor) : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(GameEvent event, Color color) {
    return Text(
      event.player ?? 'End Turn',
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTimestamp(GameEvent event) {
    Duration eventDuration = event.timestamp.difference(gameStart);
    String eventTime = "${(eventDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(eventDuration.inSeconds % 60).toString().padLeft(2, '0')}";
    return Text(
      eventTime,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case "Airball":
        return Colors.blue;
      case "Bitchcup":
        return Colors.red;
      case "Normal Hit":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case "Airball":
        return BeerpongIcons.airball;
      case "Bitchcup":
        return Icons.warning;
      case "Normal Hit":
        return Icons.sports_bar;
      default:
        return Icons.sports;
    }
  }
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
            content: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            imagePath: 'assets/frog_island.svg', // Replace with your image path
            content: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            imagePath: 'assets/cat_boxing.svg', // Replace with your image path
            content: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
  return Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 16.0, vertical: 20), // Add side margins
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12), // Rounded corners for the box
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[800], // Fallback background color
        ),
        child: Stack(
          children: [
            // SVG Background
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/sun-tornado.svg', // Replace with your SVG path
                fit: BoxFit.cover, // Ensure the SVG fills the container
              ),
            ),
            Column(
              children: [
                const Text(
                  'Round 16',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamLogo('assets/avatars/blue_team.svg', 'Team Blue'),
                    Column(
                      children: [
                        Text(
                          '${totalScore(team1).round()} : ${totalScore(team2).round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildTeamLogo('assets/avatars/red_team.svg', 'Team Red'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                left: (((team1Value + 1) / (maxStatValue + 1)) *
                                        100)
                                    .toDouble(),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: team1.color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Positioned(
                                right:
                                    (((team2Value + 1) / (maxStatValue + 1)) *
                                            100)
                                        .toDouble(),
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: team2.color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  /*
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
                      ],*/
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _buildCupLayoutsRow(Team team1, Team team2) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.2),
            Colors.grey.shade600,
            Colors.amber.withOpacity(0.2)
          ],
          stops: const [0.0, 0.5, 1.0], // Ensures the center color is at the midpoint
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ), // Background color for the container
        borderRadius: BorderRadius.circular(20.0), // Rounded corners
      ),
      child: Stack(
        children: [
          // Left Cup Layout
          Positioned(
            right: 160, // tricked the padding but overflows in the middle
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
            left: 160, // tricked the padding but overflows in the middle
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
              margin: const EdgeInsets.symmetric(
                  horizontal: 16), // Margin to the sides
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              child: const Icon(
                Icons.info,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 16), // Margin to the sides
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
