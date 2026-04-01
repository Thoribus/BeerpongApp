import 'package:flutter/material.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/screens/game/dialog_helpers.dart';
import 'package:beerpongapp/widgets/app_tab_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String gameMode;
  final List<String> specialRules;

  LiveGameData({
    required this.team1,
    required this.team2,
    required this.gameId,
    required this.gameStart,
    this.winner,
    this.gameMode = '',
    this.specialRules = const [],
  });
}

class LiveGameStatsScreenState extends State<LiveGameStatsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService.instance;
  int _currentTabPage = 0;
  late PageController _tabPageController;
  LiveGameData? _cachedGameData;
  bool _dialogShown = false;
  bool _gameAlreadyOver = false;

  // Animation controller for the LIVE badge pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentTabPage);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          _cachedGameData?.winner != null ? context.loc.liveGameSummary : context.loc.liveGameTitle,
          style: TextStyle(
            color: c.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: c.onBackground),
      ),
      backgroundColor: c.background,
      body: Column(
        children: [
          AppTabBar(
            tabs: [context.loc.liveTabTable, context.loc.liveTabStats, context.loc.liveTabTimeline],
            selectedIndex: _currentTabPage,
            onTabSelected: (index) {
              setState(() {
                _currentTabPage = index;
              });
            },
            pageController: _tabPageController,
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getGameDocStream(widget.gameId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(context.loc.liveGameError));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text(context.loc.liveGameNotFound));
                }

                final gameDataRaw =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final team1 = Team.fromJson(gameDataRaw['team1']);
                final team2 = Team.fromJson(gameDataRaw['team2']);
                final gameStart = gameDataRaw['timestamp'].toDate();
                final winner = gameDataRaw['winner'];
                final gameId = widget.gameId;
                final gameMode = gameDataRaw['gameMode'] as String? ?? '';
                final specialRules =
                    ((gameDataRaw['specialRules'] as List?) ?? [])
                        .cast<String>();

                final updatedGameData = LiveGameData(
                  team1: team1,
                  team2: team2,
                  gameId: gameId,
                  gameStart: gameStart,
                  winner: winner,
                  gameMode: gameMode,
                  specialRules: specialRules,
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
                    if (_cachedGameData == null) {
                      // First data load — game was already over when screen opened
                      _gameAlreadyOver = true;
                    } else if (!_gameAlreadyOver) {
                      _dialogShown = true;
                      final winningPlayers = (winner == 'Team Blue')
                          ? team1.players
                          : team2.players;
                      DialogHelpers.showGameEndDialog(context, winningPlayers);
                    }
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
        _buildHeader(gameData),
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

  Widget _buildHeader(LiveGameData gameData) {
    final c = AppColors.of(context);
    final team1 = gameData.team1;
    final team2 = gameData.team2;
    final isLive = gameData.winner == null;

    final chips = <String>[
      if (gameData.gameMode.isNotEmpty) gameData.gameMode,
      ...gameData.specialRules,
    ];

    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // Score row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team 1 side
              Expanded(
                child: _buildTeamSide(
                  team: team1,
                  alignment: CrossAxisAlignment.start,
                  c: c,
                ),
              ),

              // Centre column: score + badge
              Column(
                children: [
                  Text(
                    '${totalScore(team1).round()}  :  ${totalScore(team2).round()}',
                    style: TextStyle(
                      color: c.onBackground,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  isLive ? _buildLiveBadge() : _buildFinalBadge(c),
                ],
              ),

              // Team 2 side
              Expanded(
                child: _buildTeamSide(
                  team: team2,
                  alignment: CrossAxisAlignment.end,
                  c: c,
                ),
              ),
            ],
          ),

          // Chips row (game mode + special rules)
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: chips
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: c.subtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSide({
    required Team team,
    required CrossAxisAlignment alignment,
    required AppColors c,
  }) {
    final cupsLeft = team.cups.where((cup) => cup.isVisible).length;
    final teamName = team.color == const Color(0xFF2196F3) ||
            (team.color.b * 255.0).round() > (team.color.r * 255.0).round()
        ? 'Team Blue'
        : 'Team Red';

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          teamName,
          style: TextStyle(
            color: team.color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.loc.liveCupsLeft(cupsLeft),
          style: TextStyle(
            color: c.subtle,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              context.loc.liveBadgeLive,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalBadge(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.loc.liveBadgeFinal,
        style: TextStyle(
          color: c.subtle,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  num totalScore(Team team) {
    return team.players.map((player) => player.score).reduce((a, b) => a + b);
  }
}
