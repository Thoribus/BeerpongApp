import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';

// new screens/tabs
import 'package:beerpongapp/screens/liveticker/cup_layout_tab.dart';
import 'package:beerpongapp/screens/liveticker/match_stats_tab.dart';
import 'package:beerpongapp/screens/liveticker/timeline_tab.dart';

class LiveGameStatsScreen extends StatefulWidget {
  final String gameId;

  const LiveGameStatsScreen({super.key, required this.gameId});

  @override
  LiveGameStatsScreenState createState() => LiveGameStatsScreenState();
}

class LiveGameData {
  final Team team1;
  final Team team2;
  final String gameId;
  final DateTime gameStart;
  final String? winner;

  LiveGameData({
    required this.team1,
    required this.team2,
    required this.gameId,
    required this.gameStart,
    this.winner,
  });
}

class LiveGameStatsScreenState extends State<LiveGameStatsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentTabPage = 0;
  late PageController _tabPageController;
  late DateTime gameStart;
  LiveGameData? _cachedGameData;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentTabPage);
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: const Color(0xFFFF9800),
          title: const Text(
            'Live Ticker',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTabPageSelector(),
          // Use only ONE Expanded to take full remaining space
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getGameDocStream(widget.gameId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Game not found.'));
                }

                final gameDataRaw =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final team1 = Team.fromJson(gameDataRaw['team1']);
                final team2 = Team.fromJson(gameDataRaw['team2']);
                final gameStart = gameDataRaw['timestamp'].toDate();
                final winner = gameDataRaw['winner'];
                final gameId = widget.gameId;

                final updatedGameData = LiveGameData(
                  team1: team1,
                  team2: team2,
                  gameId: gameId,
                  gameStart: gameStart,
                  winner: winner,
                );

                // Update cache & dialog outside the build method
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  final shouldUpdateCache = _cachedGameData == null ||
                      _cachedGameData!.team1 != team1 ||
                      _cachedGameData!.team2 != team2 ||
                      _cachedGameData!.winner != winner;

                  if (shouldUpdateCache) {
                    setState(() {
                      _cachedGameData = updatedGameData;
                    });
                  }

                  if (winner != null &&
                      winner.toString().isNotEmpty &&
                      !_dialogShown) {
                    _dialogShown = true;
                    final winningPlayers =
                        (winner == 'Team Blue') ? team1.players : team2.players;
                    DialogHelpers.showGameEndDialog(context, winningPlayers);
                  }
                });

                // Render UI only when cache is available
                if (_cachedGameData == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return _buildGameTabs(_cachedGameData!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTabs(LiveGameData gameData) {
    return Column(
      children: [
        _buildTopBracket(gameData.team1, gameData.team2),
        Expanded(
          child: PageView(
            controller: _tabPageController,
            onPageChanged: (index) {
              setState(() {
                _currentTabPage = index;
              });
            },
            children: [
              CupLayoutTab(gameData: gameData),
              MatchStatsTab(gameData: gameData),
              TimelineTab(gameData: gameData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBracket(Team team1, Team team2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Container(
        // Apply shadow and border radius here
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          // Clip only the inner content
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge, // This only affects inner content
          child: Stack(
            children: [
              // SVG Background
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/sun-tornado.svg',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Round 16',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamLogo(
                          'assets/brevard-county-manatees-1.svg', 'Team Blue'),
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
                      _buildTeamLogo(
                          'assets/hamilton-bulldogs.svg', 'Team Red'),
                    ],
                  ),
                  const SizedBox(height: 8),
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
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 4),
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

  Widget _buildTabPageSelector() {
    final List<String> tabs = ['Table', 'Statistics', 'Timeline'];

    return Container(
      height: 48,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.orange,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTabPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (_currentTabPage != index) {
                    _tabPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    // ❌ DON'T setState manually here
                    // let onPageChanged handle _currentTabPage update
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.grey.shade600
                        : Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
