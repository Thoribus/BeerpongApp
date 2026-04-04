//-------------Packages-------------------------
import 'package:beerpongapp/constants/routes.dart';
import 'package:beerpongapp/models/achievement_def.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/achievement_engine.dart';
import 'package:beerpongapp/util/debug_seeder.dart';
import 'package:beerpongapp/util/level_system.dart';
import 'package:go_router/go_router.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:provider/provider.dart';
//----------------------------------------------

//-------------Models---------------------------
import '../../models/game_statistics.dart';
import '../../models/player.dart';
//----------------------------------------------

//-------------Screens--------------------------
import '../games/breakdown_screen.dart';
import '../games/performance_screen.dart';
import '../games/personal_statistics_screen.dart';
import '../profile/achievements_screen.dart';
//----------------------------------------------

//-------------Widgets--------------------------
import '../../widgets/app_tab_bar.dart';
//----------------------------------------------

import 'package:beerpongapp/util/localization_extensions.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  int _currentTabPage = 0; // Default to History tab
  late final PageController _tabPageController;

  List<GameStatistics> games = [];
  bool isLoading = true;
  bool hasError = false;
  late User user;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _currentTabPage);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      isLoading = false;
      return;
    }
    user = userProvider.user!;
    _retrieveGames();
  }

  Future<void> _retrieveGames() async {
    try {
      games = await FirestoreService.instance.retrieveGames(user);
    } catch (e) {
      hasError = true;
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Widget _buildTabPageSelector() {
    return AppTabBar(
      tabs: [context.loc.statsTabStats, context.loc.statsTabPerformance, context.loc.statsTabProgress, context.loc.statsTabBreakdown, context.loc.statsTabHistory],
      selectedIndex: _currentTabPage,
      onTabSelected: (index) {
        setState(() => _currentTabPage = index);
      },
      pageController: _tabPageController,
      backgroundColor: AppTheme.tabBarBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.user == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: c.subtle, size: 48),
              const SizedBox(height: 16),
              Text(
                context.loc.statsSignInPrompt,
                style: TextStyle(color: c.onBackground, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async => userProvider.signIn(),
                child: Text(context.loc.btnSignInGoogle),
              ),
            ],
          ),
        ),
      );
    }
    user = userProvider.user!;

    if (isLoading) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Text(
            context.loc.statsFailedToLoad,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildTabPageSelector(),
          Expanded(
            child: PageView(
              controller: _tabPageController,
              onPageChanged: (index) {
                setState(() => _currentTabPage = index);
              },
              children: [
                PersonalStatisticsScreen(user: user, games: games),
                PerformanceScreen(user: user),
                _ProgressTab(user: user),
                BreakdownScreen(user: user, games: games),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameStatistics game, int index) {
    final c = AppColors.of(context);
    final bool userWon = game.winningTeam == 'Team 1'
        ? game.team1Players.any((p) => p.name == user.username)
        : game.team2Players.any((p) => p.name == user.username);

    final accentColor =
        userWon ? Colors.greenAccent.shade400 : Colors.redAccent.shade200;

    final allPlayers = game.team1Players + game.team2Players;
    final userPlayer = allPlayers.where((p) => p.name == user.username).firstOrNull;
    final userHitRate = userPlayer != null && userPlayer.throws > 0
        ? (userPlayer.score / userPlayer.throws * 100).toStringAsFixed(0)
        : '--';

    final t1Cups = game.team1Players.fold(0, (s, p) => s + p.cupsHit.length);
    final t2Cups = game.team2Players.fold(0, (s, p) => s + p.cupsHit.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.15), c.card],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).onBackground.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withValues(alpha: 0.2),
            child: Icon(
              userWon ? Icons.emoji_events : Icons.cancel,
              color: accentColor,
              size: 18,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd.MM.yy').format(game.date),
                      style: TextStyle(
                        color: c.onBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Cup scores
                  Text(
                    '$t1Cups',
                    style: TextStyle(
                      color: game.winningTeam == 'Team 1'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('–',
                        style: TextStyle(color: c.subtle, fontSize: 13)),
                  ),
                  Text(
                    '$t2Cups',
                    style: TextStyle(
                      color: game.winningTeam == 'Team 2'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hit rate badge
                  if (userPlayer != null)
                    _metaBadge('$userHitRate%', Colors.amber),
                ],
              ),
              // Metadata badges row
              if (game.durationSeconds != null ||
                  game.gameMode != 'Single Game' ||
                  (game.cupsRemainingWinner != null &&
                      game.cupsRemainingWinner! >= 5) ||
                  game.specialRules.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (game.durationSeconds != null)
                        _metaBadge(
                          _formatDuration(game.durationSeconds!),
                          Colors.blueGrey,
                        ),
                      if (game.gameMode != 'Single Game')
                        _metaBadge(game.gameMode, Colors.purple),
                      if (game.cupsRemainingWinner != null &&
                          game.cupsRemainingWinner! >= 5)
                        _metaBadge(
                          '+${game.cupsRemainingWinner}',
                          Colors.green,
                        ),
                      ...game.specialRules.map(
                        (r) => _metaBadge(r, Colors.teal),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            tooltip: context.loc.statsLiveView,
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.of(context).muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.push(AppRoutes.spectateLivePath(game.id)),
          ),
          children: [
            _buildInlinePlayerTable(context, 'Team 1', game.team1Players, mvpName: _mvpName(game)),
            const SizedBox(height: 8),
            _buildInlinePlayerTable(context, 'Team 2', game.team2Players, mvpName: _mvpName(game)),
          ],
        ),
      ),
    );
  }

  /// Returns the name of the player with the highest hit rate in [game].
  String _mvpName(GameStatistics game) {
    final all = game.team1Players + game.team2Players;
    Player? mvp;
    double best = -1;
    for (final p in all) {
      final rate = p.throws > 0 ? p.score / p.throws : 0.0;
      if (rate > best) {
        best = rate;
        mvp = p;
      }
    }
    return mvp?.name ?? '';
  }

  Widget _buildInlinePlayerTable(
      BuildContext context, String teamLabel, List<Player> players,
      {String mvpName = ''}) {
    final c = AppColors.of(context);
    final headerStyle =
        TextStyle(color: c.subtle, fontSize: 10, fontWeight: FontWeight.w600);
    final cellStyle = TextStyle(color: c.onBackground, fontSize: 11);

    const double col0 = 96; // Player name
    const double col1 = 36; // Score
    const double col2 = 42; // Throws
    const double col3 = 36; // Miss
    const double col4 = 38; // Hit%
    const double col5 = 52; // Bounce
    const double col6 = 28; // 🔥
    const double col7 = 30; // Def

    Widget cell(Widget child, double width,
            {TextAlign align = TextAlign.center}) =>
        SizedBox(width: width, child: child);

    Widget headerCell(String label, double width) =>
        cell(Text(label, style: headerStyle, textAlign: TextAlign.center), width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamLabel,
            style: TextStyle(
                color: c.subtle,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: UnconstrainedBox(
            constrainedAxis: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header row
              Row(children: [
                cell(Text(context.loc.statsColumnPlayer, style: headerStyle), col0),
                headerCell(context.loc.statsColumnScore, col1),
                headerCell(context.loc.liveStatThrows, col2),
                headerCell(context.loc.statsColumnMiss, col3),
                headerCell(context.loc.statsColumnHitRate, col4),
                headerCell(context.loc.statsColumnBounce, col5),
                headerCell('🔥', col6),
                headerCell(context.loc.statsColumnDef, col7),
              ]),
              const SizedBox(height: 2),
              // Data rows
              ...players.map((p) {
                final hr = p.throws > 0
                    ? '${(p.score / p.throws * 100).toStringAsFixed(0)}%'
                    : '--';
                final bounce = p.bounceAttempts > 0
                    ? '${p.bounceMakes}/${p.bounceAttempts}'
                    : '--';
                final isMvp = p.name == mvpName && mvpName.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    SizedBox(
                      width: col0,
                      child: Row(
                        children: [
                          if (isMvp)
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Text('⭐',
                                  style: TextStyle(fontSize: 10)),
                            ),
                          Expanded(
                            child: Text(
                              p.name.length > 11
                                  ? '${p.name.substring(0, 11)}…'
                                  : p.name,
                              style: isMvp
                                  ? cellStyle.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold)
                                  : cellStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    cell(Text('${p.score.toInt()}',
                        style: cellStyle, textAlign: TextAlign.center), col1),
                    cell(Text('${p.throws}',
                        style: cellStyle, textAlign: TextAlign.center), col2),
                    cell(Text('${p.misses}',
                        style: cellStyle, textAlign: TextAlign.center), col3),
                    cell(Text(hr,
                        style: cellStyle.copyWith(color: Colors.amber),
                        textAlign: TextAlign.center), col4),
                    cell(Text(bounce,
                        style: cellStyle.copyWith(color: Colors.purple.shade200),
                        textAlign: TextAlign.center), col5),
                    cell(Text('${p.onFire}',
                        style: cellStyle.copyWith(color: Colors.deepOrange),
                        textAlign: TextAlign.center), col6),
                    cell(Text('${p.defended}',
                        style: cellStyle.copyWith(color: Colors.indigo.shade200),
                        textAlign: TextAlign.center), col7),
                  ]),
                );
              }),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _metaBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    return '${m}min';
  }

  // ── Streak helpers ────────────────────────────────────────────────────────

  bool _userWonGame(GameStatistics g) => g.winningTeam == 'Team 1'
      ? g.team1Players.any((p) => p.name == user.username)
      : g.team2Players.any((p) => p.name == user.username);

  ({int length, bool isWin}) _computeCurrentStreak() {
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.isEmpty) return (length: 0, isWin: true);
    final firstWon = _userWonGame(sorted.first);
    int count = 0;
    for (final g in sorted) {
      if (_userWonGame(g) == firstWon) {
        count++;
      } else {
        break;
      }
    }
    return (length: count, isWin: firstWon);
  }

  // ── Streak banner ─────────────────────────────────────────────────────────

  Widget _buildStreakBanner() {
    final c = AppColors.of(context);
    final streak = _computeCurrentStreak();
    final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
    final last10 = sorted.take(10).toList();
    final wins10 = last10.where(_userWonGame).length;
    final losses10 = last10.length - wins10;
    final pct10 = last10.isEmpty ? 0 : (wins10 / last10.length * 100).round();

    final streakColor = streak.isWin ? Colors.green : Colors.redAccent;
    final streakLabel =
        '${streak.length}${streak.isWin ? 'W' : 'L'} streak';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: streakColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            streak.isWin ? Icons.local_fire_department : Icons.trending_down,
            color: streakColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.loc.statsCurrentStreak(streakLabel),
              style: TextStyle(
                color: c.onBackground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.loc.statsLast10Record(last10.length, wins10, losses10),
                style: TextStyle(color: c.onBackground, fontSize: 12),
              ),
              Text(
                '$pct10%',
                style: TextStyle(
                  color: wins10 >= losses10 ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final c = AppColors.of(context);
    if (games.isEmpty) {
      return Center(
        child: Text(
          context.loc.statsNoGamesYet,
          style: TextStyle(color: c.subtle),
        ),
      );
    }
    return Column(
      children: [
        _buildStreakBanner(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: games.length,
            itemBuilder: (context, index) => _buildGameCard(games[index], index),
          ),
        ),
      ],
    );
  }
}

// ── Progress tab ─────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final User user;
  const _ProgressTab({required this.user});

  static const _tierLevels = [
    (LevelTier.benchWarmer, 1),
    (LevelTier.partyStarter, 6),
    (LevelTier.cupHunter, 11),
    (LevelTier.tableRegular, 16),
    (LevelTier.foamRoller, 21),
    (LevelTier.bounceArtist, 26),
    (LevelTier.deathCupDealer, 31),
    (LevelTier.pongVeteran, 36),
    (LevelTier.islandMaster, 41),
    (LevelTier.pongLegend, 46),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = LevelSystem.levelFromXp(user.xp);
    final tier = LevelSystem.tierForLevel(level);
    final progress = LevelSystem.progressInLevel(user.xp);
    final toNext = LevelSystem.xpToNextLevel(user.xp);
    final isMax = level >= LevelSystem.maxLevel;

    final grouped = AchievementEngine.evaluateGrouped(user);
    final upcoming = AchievementEngine.upcomingUnlocks(user).take(5).toList();

    final tierIndex = _tierLevels.indexWhere((t) => t.$1 == tier);
    final hasNextTier = tierIndex < _tierLevels.length - 1;
    final nextTierLevel = hasNextTier ? _tierLevels[tierIndex + 1].$2 : null;
    final nextTier = hasNextTier ? _tierLevels[tierIndex + 1].$1 : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── View all achievements button ───────────────────────────────────
        OutlinedButton.icon(
          icon: const Icon(Icons.emoji_events_outlined, size: 16),
          label: Text(context.loc.statsViewAllAchievements),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
          ),
          onPressed: () => context.push(AppRoutes.achievements),
        ),

        const SizedBox(height: 16),

        // ── XP / Level card ───────────────────────────────────────────────
        Card(
          color: c.card,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tier.color, tier.color.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tier.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      context.loc.labelLevelShort(level),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tier.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: c.border,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(tier.color),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMax
                            ? context.loc.statsMaxLevelReached(user.xp)
                            : context.loc.statsXpProgress(user.xp, toNext, level + 1),
                        style: TextStyle(fontSize: 11, color: c.subtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Next tier callout ─────────────────────────────────────────────
        if (hasNextTier && nextTier != null && nextTierLevel != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: nextTier.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: nextTier.color.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_open_outlined,
                    color: nextTier.color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.loc.statsReachLevelUnlock(nextTierLevel, nextTier.displayName),
                    style: TextStyle(
                        color: nextTier.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${nextTierLevel - level} lvl${nextTierLevel - level == 1 ? '' : 's'}',
                  style: TextStyle(
                      color: nextTier.color.withValues(alpha: 0.7),
                      fontSize: 12),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // ── Tier roadmap ──────────────────────────────────────────────────
        Text(context.loc.statsTierRoadmap,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.onBackground)),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tierLevels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (t, minLv) = _tierLevels[i];
              final isCurrent = t == tier;
              final isUnlocked = level >= minLv;
              return Container(
                width: 90,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? t.color.withValues(alpha: 0.18)
                      : isUnlocked
                          ? c.card
                          : c.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? t.color
                        : isUnlocked
                            ? t.color.withValues(alpha: 0.4)
                            : c.border.withValues(alpha: 0.3),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUnlocked)
                      Icon(Icons.lock,
                          size: 11,
                          color: c.subtle.withValues(alpha: 0.5)),
                    Text(
                      t.displayName,
                      style: TextStyle(
                        color: isUnlocked
                            ? t.color
                            : c.subtle.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.loc.labelLevelShort(minLv)}+',
                      style: TextStyle(
                        color: isUnlocked
                            ? t.color.withValues(alpha: 0.7)
                            : c.subtle.withValues(alpha: 0.3),
                        fontSize: 9,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: t.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // ── Achievement category overview ─────────────────────────────────
        Text(context.loc.statsAchievementProgress,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.onBackground)),
        const SizedBox(height: 10),
        for (final entry in grouped.entries)
          _StatsCategoryProgressRow(
              category: entry.key, progressList: entry.value),

        const SizedBox(height: 24),

        // ── Unlocked titles ───────────────────────────────────────────────
        if (user.unlockedTitles.isNotEmpty) ...[
          Text(context.loc.statsUnlockedTitles,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.onBackground)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.unlockedTitles.map((title) {
              final isEquipped = user.title == title;
              final color =
                  AchievementsScreen.getColorForUnlockedTitle(title, user);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: isEquipped ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color
                          .withValues(alpha: isEquipped ? 0.8 : 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEquipped) ...[
                      Icon(Icons.check_circle, color: color, size: 12),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: isEquipped
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── Upcoming unlocks ──────────────────────────────────────────────
        if (upcoming.isNotEmpty) ...[
          Text(context.loc.statsAlmostThere,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.onBackground)),
          const SizedBox(height: 10),
          for (final p in upcoming) _StatsUpcomingTile(progress: p),
        ],

        // ── Debug seed button (debug builds only) ─────────────────────────
        if (kDebugMode) ...[
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Seed Test Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
            onPressed: () async {
              final provider =
                  Provider.of<UserProvider>(context, listen: false);
              try {
                await DebugSeeder.seedUser(user.id);
                await provider.loadUser();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test data seeded!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seed failed: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }
}

// ── Category progress row ──────────────────────────────────────────────────

class _StatsCategoryProgressRow extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementProgress> progressList;

  const _StatsCategoryProgressRow(
      {required this.category, required this.progressList});

  static IconData _iconFor(AchievementCategory cat) => switch (cat) {
        AchievementCategory.performance => Icons.local_fire_department,
        AchievementCategory.consistency => Icons.repeat,
        AchievementCategory.accuracy => Icons.gps_fixed,
        AchievementCategory.social => Icons.group,
        AchievementCategory.fun => Icons.celebration,
      };

  static Color _colorFor(AchievementCategory cat) => switch (cat) {
        AchievementCategory.performance => Colors.deepOrange,
        AchievementCategory.consistency => Colors.green,
        AchievementCategory.accuracy => Colors.blue,
        AchievementCategory.social => Colors.purple,
        AchievementCategory.fun => Colors.amber,
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = _colorFor(category);
    final totalStages =
        progressList.fold(0, (sum, p) => sum + p.def.thresholds.length);
    final unlockedStages =
        progressList.fold(0, (sum, p) => sum + p.currentStageIndex);
    final pct = totalStages > 0 ? unlockedStages / totalStages : 0.0;
    final label =
        category.name[0].toUpperCase() + category.name.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: c.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(_iconFor(category), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: c.onBackground,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$unlockedStages / $totalStages stages',
                        style: TextStyle(color: c.subtle, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsUpcomingTile extends StatelessWidget {
  final AchievementProgress progress;
  const _StatsUpcomingTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final c = AppColors.of(context);
    final nextStageLabel = p.def.stageNames.length > p.currentStageIndex
        ? p.def.stageNames[p.currentStageIndex]
        : 'Max';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(p.def.icon, color: p.stageColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.def.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.onBackground,
                            fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: p.stageColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        nextStageLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: p.stageColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.progressToNextStage,
                    minHeight: 5,
                    backgroundColor: c.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(p.stageColor),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.currentValue} / ${p.nextThreshold} · ${p.gapToNextStage} to go',
                  style: TextStyle(fontSize: 10, color: c.subtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class GameDetailsPage extends StatefulWidget {
  final GameStatistics game;

  const GameDetailsPage({super.key, required this.game});

  @override
  GameDetailsPageState createState() => GameDetailsPageState();
}

class GameDetailsPageState extends State<GameDetailsPage> {
  late PageController _pageController;
  int _currentPage = 0;
  String selectedTeam = 'Both Teams';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.statsGameStatistics,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _currentPage == 0
                    ? null
                    : () {
                        _pageController.jumpToPage(0);
                      },
                child: Text(
                  context.loc.statsViewTeam,
                  style: TextStyle(
                    color: _currentPage == 0 ? Colors.amber : AppColors.of(context).onBackground,
                    backgroundColor: AppColors.of(context).surface,
                  ),
                ),
              ),
              VerticalDivider(
                color: AppColors.of(context).divider,
                width: 20,
                thickness: 2,
                indent: 5,
                endIndent: 5,
              ),
              TextButton(
                onPressed: _currentPage == 1
                    ? null
                    : () {
                        _pageController.jumpToPage(1);
                      },
                child: Text(
                  context.loc.statsViewGameStats,
                  style: TextStyle(
                    color: _currentPage == 1 ? Colors.amber : AppColors.of(context).onBackground,
                    backgroundColor: AppColors.of(context).surface,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              children: [
                _buildViewTableButton(widget.game),
                _buildGameStatsPage(widget.game),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.of(context).background,
    );
  }

  Widget _buildViewTableButton(GameStatistics game) {
    return ElevatedButton(
      onPressed: () {
        context.push(AppRoutes.spectateLivePath(game.id));
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
      child: Text(
        context.loc.statsViewTable,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildTeamStatsTable(
    String teamName,
    Color teamColor,
    List<Player> players,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 10,
        columns: [
          DataColumn(
            label: Text(context.loc.statsColumnPlayer, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
          DataColumn(
            label: Text(context.loc.statsColAbbrevScore, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
          DataColumn(
            label: Text(context.loc.statsColAbbrevMisses, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
          DataColumn(
            label: Text(context.loc.statsColAbbrevThrows, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
          DataColumn(
            label: Text(context.loc.statsColAbbrevAirballs, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
          DataColumn(
            label: Text(context.loc.statsColAbbrevHitRate, style: TextStyle(color: AppColors.of(context).onBackground)),
          ),
        ],
        rows: players.map((player) {
          double hitRate = player.throws > 0 ? player.score / player.throws : 0;
          return DataRow(
            cells: [
              DataCell(SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Icon(Icons.person, color: teamColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.name.length > 10
                            ? '${player.name.substring(0, 10)}...'
                            : player.name,
                        style: TextStyle(
                          color: AppColors.of(context).onBackground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.score}',
                  style: TextStyle(
                    color: AppColors.of(context).onBackground,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.misses}',
                  style: TextStyle(
                    color: AppColors.of(context).onBackground,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.throws}',
                  style: TextStyle(
                    color: AppColors.of(context).onBackground,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  '${player.airballs}',
                  style: TextStyle(
                    color: AppColors.of(context).onBackground,
                  ),
                ),
              )),
              DataCell(SizedBox(
                width: 30,
                child: Text(
                  hitRate.toStringAsFixed(2),
                  style: TextStyle(
                    color: AppColors.of(context).onBackground,
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameStatsPage(GameStatistics game) {
    Player mvp = game.team1Players[0];
    Player airballer = game.team1Players[0];
    Player missManiac = game.team1Players[0];
    Player sniper = game.team1Players[0];

    double bestHitRate = 0;

    for (var player in game.team1Players + game.team2Players) {
      if (player.score > mvp.score) {
        mvp = player;
      }
      if (player.airballs > airballer.airballs) {
        airballer = player;
      }
      if (player.misses > missManiac.misses) {
        missManiac = player;
      }
      double hitRate = player.throws > 0 ? player.score / player.throws : 0;
      if (hitRate > bestHitRate) {
        bestHitRate = hitRate;
        sniper = player;
      }
    }

    return Container(
      color: AppColors.of(context).background,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.statsAchievements,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(
                color: Colors.amber,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              _buildAchievementsSection(mvp, airballer, missManiac, sniper),
              const SizedBox(height: 20),
              Text(
                context.loc.statsTeamStatistics,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(
                color: Colors.amber,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              _buildTeamStatsTable('Team 1', Colors.blue, game.team1Players),
              const SizedBox(height: 20),
              _buildTeamStatsTable('Team 2', Colors.red, game.team2Players),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(
      Player mvp, Player airballer, Player missManiac, Player sniper) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAchievementIcon(Icons.star, context.loc.statsMvp, mvp),
            _buildAchievementIcon(Icons.air, context.loc.statsAirballer, airballer),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAchievementIcon(Icons.clear, context.loc.statsMissManiac, missManiac),
            _buildAchievementIcon(Icons.album, context.loc.statsSniper, sniper),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementIcon(IconData icon, String title, Player player) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.surfaceDark2,
          child: Icon(
            icon,
            color: Colors.amber,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.amber),
        ),
        const SizedBox(height: 4),
        Text(
          player.name.length > 10
              ? '${player.name.substring(0, 10)}...'
              : player.name,
          style: TextStyle(color: AppColors.of(context).onBackground),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
